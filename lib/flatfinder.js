const { shorten, random, combineWhenGiven } = require('lib/utils')
const Store = require('lib/store')

const notify = require('lib/notify')
const xray = require('lib/scraper')

class FlatFinder {
  constructor(source) {
    this._fullCrawl = true
    this._crawlCount = -1
    this._source = source
    this._store = new Store(source.name)
  }

  async run() {
    const { enabled, normalize, filter, name } = this._source

    if (!enabled) return

    const listings = await this._getListings()
    const newListings = listings
      .map(normalize)
      .filter(filter)
      .filter((o) => this._store.knownListings.indexOf(o.id) === -1)

    console.log(`-- ${name} : ${newListings.length} --`)

    if (newListings.length < 1) return

    for (const listing of newListings) {
      console.log(shorten(listing.title, 100))

      const separator = '\n'

      const msg =
        `*${shorten(listing.title.replace(/\*/g, ''), 45)}*\n` +
        combineWhenGiven('📍', listing.address, separator) +
        combineWhenGiven('💶', listing.price, separator) +
        combineWhenGiven('📐', listing.size, separator) +
        combineWhenGiven('📐', listing.property_size, separator) +
        combineWhenGiven('🛌', listing.rooms, separator) +
        '\n' +
        `[Link to offer](${listing.link})` + (listing.address ? ' | [Google Maps](https://www.google.com/maps/search/?api=1&query=' + listing.address + ')' : "")

      await notify.send(msg)
      this._store.addListing(listing.id)

      await new Promise((r) => setTimeout(r, random(1050, 2200)))
    }
  }

  _getListings() {
    const { crawlFields, crawlContainer, paginate, url } = this._source

    return new Promise((resolve, reject) => {
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
    })
  }
}

module.exports = FlatFinder
