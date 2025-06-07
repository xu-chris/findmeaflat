const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  const rooms = o.rooms.split(' Zi.')[0] + ' Zimmer'
  const id = o.id.split('classified-card-mfe-')[1]
  return {...o, rooms, id}
}

function applyBlacklist(o) {
  const titleNotBlacklisted = !utils.isOneOf(o.title, config.blacklist)
  const descNotBlacklisted = !utils.isOneOf(o.description, config.blacklist)

  return titleNotBlacklisted && descNotBlacklisted
}

const enabled = !!config.providers.immowelt

const immowelt = {
  name: 'immowelt',
  enabled,
  url: !enabled || config.providers.immowelt.url,
  crawlContainer: 'div[data-testid="serp-core-scrollablelistview-testid"] [data-testid|="serp-core-classified-card-testid"]',
  crawlFields: {
    id: 'div@data-testid',
    price: '[data-testid="cardmfe-price-testid"] | removeNewline | trim',
    size: '[data-testid="cardmfe-keyfacts-testid"] div:nth-child(3) | removeNewline | trim',
    title: 'a@title',
    link: 'a@href',
    description: 'a [class|="estateFacts"] div:nth-child(2) span | removeNewline | trim',
    rooms: '[data-testid="cardmfe-keyfacts-testid"] div:nth-child(1) | removeNewline | trim',
    address: '[data-testid="cardmfe-description-box-address"] | removeNewline | trim'
  },
  paginate: '[aria-label="nächste seite"]',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(immowelt, { debugRawHtml: config.debugRawHtml })
