require('rootpath')()

const config = require('conf/config.json')
const fs = require('fs')
const util = require('util')

const INTERVAL_MINUTES = config.intervalInMinutes || 5
const PATH = './lib/sources'
const INTERVAL = INTERVAL_MINUTES * 60 * 1000

console.log(`Starting FindMeAFlat scraper with ${INTERVAL_MINUTES} minute intervals`)

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
        console.error(`Failed to load source ${src}:`, error.message)
        return null
      }
    }).filter(Boolean)
    
    console.log(`Loaded ${sources.length} sources: ${sourceFiles.map(f => f.replace('.js', '')).join(', ')}`)
  } catch (error) {
    console.error('Failed to load sources:', error.message)
    process.exit(1)
  }
}

async function main() {
  if (isRunning) {
    console.log('Previous scraping cycle still running, skipping...')
    return
  }

  isRunning = true
  const startTime = Date.now()
  
  try {
    console.log(`\n[${new Date().toISOString()}] Starting scraping cycle...`)
    
    const results = await Promise.allSettled(
      sources.map(async (source, index) => {
        try {
          console.log(`Running source ${index + 1}/${sources.length}: ${source._source?.name || 'Unknown'}`)
          return await source.run()
        } catch (error) {
          console.error(`Source ${source._source?.name || index} failed:`, error.message)
          throw error
        }
      })
    )

    const successful = results.filter(r => r.status === 'fulfilled').length
    const failed = results.filter(r => r.status === 'rejected').length
    
    console.log(`Scraping cycle completed: ${successful} successful, ${failed} failed (${Date.now() - startTime}ms)`)
    
  } catch (error) {
    console.error('Critical error in main cycle:', util.inspect(error, true, 2, true))
  } finally {
    isRunning = false
  }
}

// Graceful shutdown
function gracefulShutdown(signal) {
  console.log(`\nReceived ${signal}. Shutting down gracefully...`)
  
  if (intervalId) {
    clearInterval(intervalId)
    console.log('Stopped interval timer')
  }
  
  if (isRunning) {
    console.log('Waiting for current scraping cycle to complete...')
    // Give it 30 seconds to finish
    setTimeout(() => {
      console.log('Force exit after timeout')
      process.exit(1)
    }, 30000)
  } else {
    console.log('Goodbye!')
    process.exit(0)
  }
}

// Setup signal handlers
process.on('SIGINT', () => gracefulShutdown('SIGINT'))
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error)
  gracefulShutdown('uncaughtException')
})
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason)
})

// Initialize and start
loadSources()

if (sources.length === 0) {
  console.error('No sources loaded. Exiting.')
  process.exit(1)
}

intervalId = setInterval(main, INTERVAL)
main()
