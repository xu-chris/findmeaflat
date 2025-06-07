require('rootpath')()

const config = require('conf/config.json')
const fs = require('fs')
const util = require('util')
const logger = require('lib/logger')

const INTERVAL_MINUTES = config.intervalInMinutes || 5
const PATH = './lib/sources'
const INTERVAL = INTERVAL_MINUTES * 60 * 1000

logger.app.info(`Starting FindMeAFlat scraper with ${INTERVAL_MINUTES} minute intervals`)

let sources = []
let intervalId = null
let isRunning = false

// Load sources with error handling
function loadSources() {
  try {
    const sourceFiles = fs.readdirSync(PATH).filter(file => file.endsWith('.js'))
    sources = sourceFiles.map((src) => {
      try {
        return require(`${PATH}/${src}`)
      } catch (error) {
        logger.app.error(`Failed to load source ${src}:`, { error: error.message })
        return null
      }
    }).filter(Boolean)
    
    logger.app.info(`Loaded ${sources.length} sources: ${sourceFiles.map(f => f.replace('.js', '')).join(', ')}`)
  } catch (error) {
    logger.app.error('Failed to load sources:', { error: error.message })
    process.exit(1)
  }
}

async function main() {
  if (isRunning) {
    logger.app.warn('Previous scraping cycle still running, skipping...')
    return
  }

  isRunning = true
  const startTime = Date.now()
  
  try {
    logger.performance.cycleStart(sources.length)
    
    const results = await Promise.allSettled(
      sources.map(async (source, index) => {
        try {
          logger.scraping.start(source._source?.name || 'Unknown', source._source?.url)
          return await source.run()
        } catch (error) {
          logger.scraping.error(source._source?.name || index, error, source._source?.url)
          throw error
        }
      })
    )

    const successful = results.filter(r => r.status === 'fulfilled').length
    const failed = results.filter(r => r.status === 'rejected').length
    
    logger.performance.cycleEnd(Date.now() - startTime, successful, failed)
    
  } catch (error) {
    logger.app.error('Critical error in main cycle:', { error: error.message, stack: error.stack })
  } finally {
    isRunning = false
  }
}

// Graceful shutdown
function gracefulShutdown(signal) {
  logger.app.info(`Received ${signal}. Shutting down gracefully...`)
  
  if (intervalId) {
    clearInterval(intervalId)
    logger.app.info('Stopped interval timer')
  }
  
  if (isRunning) {
    logger.app.info('Waiting for current scraping cycle to complete...')
    // Give it 30 seconds to finish
    setTimeout(() => {
      logger.app.warn('Force exit after timeout')
      process.exit(1)
    }, 30000)
  } else {
    logger.app.info('Goodbye!')
    process.exit(0)
  }
}

// Setup signal handlers
process.on('SIGINT', () => gracefulShutdown('SIGINT'))
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
process.on('uncaughtException', (error) => {
  logger.app.error('Uncaught Exception:', { error: error.message, stack: error.stack })
  gracefulShutdown('uncaughtException')
})
process.on('unhandledRejection', (reason, promise) => {
  logger.app.error('Unhandled Rejection:', { reason, promise: promise.toString() })
})

// Initialize and start
loadSources()

if (sources.length === 0) {
  logger.app.error('No sources loaded. Exiting.')
  process.exit(1)
}

intervalId = setInterval(main, INTERVAL)
main()
