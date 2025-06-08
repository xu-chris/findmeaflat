const winston = require('winston')
const path = require('path')

// Create logs directory if it doesn't exist
const fs = require('fs')
const logsDir = path.join(__dirname, '../logs')
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true })
}

// Custom format for console output
const consoleFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.colorize(),
  winston.format.printf(({ timestamp, level, message, source, ...meta }) => {
    const sourceInfo = source ? `[${source}] ` : ''
    const metaInfo = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : ''
    return `${timestamp} ${level}: ${sourceInfo}${message}${metaInfo}`
  })
)

// Custom format for file output
const fileFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json()
)

// Create Winston logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  defaultMeta: { service: 'findmeaflat' },
  transports: [
    // Console transport
    new winston.transports.Console({
      format: consoleFormat,
      level: process.env.NODE_ENV === 'production' ? 'warn' : 'debug'
    }),
    
    // File transport for all logs
    new winston.transports.File({
      filename: path.join(logsDir, 'app.log'),
      format: fileFormat,
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    
    // File transport for errors only
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      format: fileFormat,
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    
    // File transport for scraping activity
    new winston.transports.File({
      filename: path.join(logsDir, 'scraping.log'),
      format: fileFormat,
      maxsize: 10485760, // 10MB
      maxFiles: 3,
      level: 'info'
    })
  ]
})

// Create specialized loggers for different components
const createSourceLogger = (sourceName) => {
  return {
    debug: (message, meta = {}) => logger.debug(message, { source: sourceName, ...meta }),
    info: (message, meta = {}) => logger.info(message, { source: sourceName, ...meta }),
    warn: (message, meta = {}) => logger.warn(message, { source: sourceName, ...meta }),
    error: (message, meta = {}) => logger.error(message, { source: sourceName, ...meta })
  }
}

// Helper methods for common logging patterns
const loggers = {
  // Main application logger
  app: {
    debug: (message, meta = {}) => logger.debug(message, { component: 'app', ...meta }),
    info: (message, meta = {}) => logger.info(message, { component: 'app', ...meta }),
    warn: (message, meta = {}) => logger.warn(message, { component: 'app', ...meta }),
    error: (message, meta = {}) => logger.error(message, { component: 'app', ...meta })
  },
  
  // Scraping activity logger
  scraping: {
    start: (sourceName, url) => logger.info('Starting scrape', { 
      component: 'scraping', 
      source: sourceName, 
      url 
    }),
    
    found: (sourceName, count, newCount) => logger.info('Listings processed', { 
      component: 'scraping', 
      source: sourceName, 
      total: count, 
      new: newCount 
    }),
    
    error: (sourceName, error, url) => logger.error('Scraping failed', { 
      component: 'scraping', 
      source: sourceName, 
      url,
      error: error.message,
      stack: error.stack 
    }),
    
    complete: (sourceName, duration) => logger.info('Scrape completed', { 
      component: 'scraping', 
      source: sourceName, 
      duration: `${duration}ms` 
    })
  },
  
  // Notification logger
  notification: {
    sent: (listingId, title) => logger.info('Notification sent', { 
      component: 'notification', 
      listingId, 
      title: title?.substring(0, 50) 
    }),
    
    failed: (listingId, error) => logger.error('Notification failed', { 
      component: 'notification', 
      listingId, 
      error: error.message 
    })
  },
  
  // Performance logger
  performance: {
    cycleStart: (sourcesCount) => logger.info('Scraping cycle started', { 
      component: 'performance', 
      sources: sourcesCount 
    }),
    
    cycleEnd: (duration, successful, failed) => logger.info('Scraping cycle completed', { 
      component: 'performance', 
      duration: `${duration}ms`, 
      successful, 
      failed 
    })
  }
}

// Create source-specific loggers
loggers.createSourceLogger = createSourceLogger

// Graceful shutdown method that can be called by main app
const shutdown = () => {
  return new Promise((resolve) => {
    logger.end(() => {
      resolve()
    })
  })
}

// Export shutdown method
loggers.shutdown = shutdown

module.exports = loggers