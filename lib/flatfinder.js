const { shorten, random, combineWhenGiven } = require('lib/utils')
const Store = require('lib/store')
const logger = require('lib/logger')

const notify = require('lib/notify')
const xray = require('lib/scraper')

class FlatFinder {
  constructor(source, options = {}) {
    this._fullCrawl = true
    this._crawlCount = -1
    this._source = source
    this._store = new Store(source.name)
    this._debugRawHtml = options.debugRawHtml || false
    this._logger = logger.createSourceLogger(source.name)
  }

  async run() {
    const { enabled, normalize, filter, name } = this._source

    if (!enabled) return

    const listings = await this._getListings()

    // Use Set for O(1) lookup performance
    const knownListingsSet = new Set(this._store.knownListings)

    const newListings = listings
      .map(normalize)
      .filter(filter)
      .filter((o) => !knownListingsSet.has(o.id))

    this._logger.info(`Found ${newListings.length} new listings`, { total: listings.length, new: newListings.length })

    if (newListings.length < 1) return

    // Process listings one by one to avoid overwhelming the system
    for (const listing of newListings) {
      this._logger.debug(`Processing listing: ${shorten(listing.title, 100)}`, { listingId: listing.id })

      const separator = '\n'
      const msg = this._formatListingMessage(listing, separator)

      try {
        await notify.send(msg)
        logger.notification.sent(listing.id, listing.title)
        this._store.addListing(listing.id)
        await new Promise((r) => setTimeout(r, random(1050, 2200)))
      } catch (error) {
        logger.notification.failed(listing.id, error)
        // Still add to store to avoid retrying
        this._store.addListing(listing.id)
      }
    }
  }

  _getListings() {
    const { crawlFields, crawlContainer, paginate, url } = this._source

    return new Promise((resolve, reject) => {
      if (this._debugRawHtml) {
        // Debug: Log raw HTML content first
        this._logger.debug(`Fetching raw HTML from: ${url}`)

        xray(url, 'html')((err, html) => {
          if (err) {
            this._logger.error('Error fetching raw HTML', { error: err.message, url })
          } else {
            this._logger.debug('Raw HTML fetched successfully', { 
              htmlLength: html?.length || 0,
              preview: html?.substring(0, 500) || 'No content'
            })
          }

          this._performScraping(resolve, reject)
        })
      } else {
        this._performScraping(resolve, reject)
      }
    })
  }

  _performScraping(resolve, reject) {
    const { crawlFields, crawlContainer, paginate, url } = this._source

    let x = xray(url, crawlContainer, [crawlFields])
    if (paginate && (this._fullCrawl || (this._crawlCount++ % 10 === 0))) {
      this._fullCrawl = false
      x = x
        .paginate(paginate)
        .limit(20)
        .abort(function (_result, _nextUrl) {
          // Pagination progress indicator
          return false
        })
    }

    x((err, listings) => {
      return err ? reject(err) : resolve(listings)
    })
  }

  _formatListingMessage(listing, separator) {
    return `*${shorten(listing.title.replace(/\*/g, ''), 45)}*\n` +
      combineWhenGiven('📍', listing.address, separator) +
      combineWhenGiven('💶', listing.price, separator) +
      combineWhenGiven('📐', listing.size, separator) +
      combineWhenGiven('📐', listing.property_size, separator) +
      combineWhenGiven('🛌', listing.rooms, separator) +
      '\n' +
      `[Link to offer](${listing.link})` +
      (listing.address ? ' | [Google Maps](https://www.google.com/maps/search/?api=1&query=' + listing.address + ')' : "")
  }
}

module.exports = FlatFinder
