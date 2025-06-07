const { shorten, random, combineWhenGiven } = require('lib/utils')
const Store = require('lib/store')

const notify = require('lib/notify')
const xray = require('lib/scraper')

class FlatFinder {
  constructor(source, options = {}) {
    this._fullCrawl = true
    this._crawlCount = -1
    this._source = source
    this._store = new Store(source.name)
    this._debugRawHtml = options.debugRawHtml || false
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

    console.log(`-- ${name} : ${newListings.length} --`)

    if (newListings.length < 1) return

    // Process listings one by one to avoid overwhelming the system
    for (const listing of newListings) {
      console.log(shorten(listing.title, 100))

      const separator = '\n'
      const msg = this._formatListingMessage(listing, separator)

      try {
        await notify.send(msg)
        this._store.addListing(listing.id)
        await new Promise((r) => setTimeout(r, random(1050, 2200)))
      } catch (error) {
        console.error(`Error sending notification for listing ${listing.id}:`, error)
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
        console.log(`\n=== RAW HTML CONTENT FROM: ${url} ===`)

        xray(url, 'html')((err, html) => {
          if (err) {
            console.error('Error fetching raw HTML:', err)
          } else {
            console.log('Raw HTML length:', html?.length || 0)
            console.log('Raw HTML preview:')
            console.log('-'.repeat(80))
            console.log(html || 'No content')
            console.log('-'.repeat(80))
            console.log('=== END RAW HTML ===\n')
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
          process.stdout.write('.')
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
