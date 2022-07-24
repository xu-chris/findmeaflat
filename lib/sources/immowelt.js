const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  const rooms = o.rooms.split(' Zi.')[0] + ' Zimmer'
  return {...o, rooms}
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
  crawlContainer: 'div[data-test="searchlist"] [class|="EstateItem"]',
  crawlFields: {
    id: 'a@id',
    price: 'a [data-test="price"] | removeNewline | trim',
    size: 'a [data-test="area"] | removeNewline | trim',
    title: 'a h2',
    link: 'a@href',
    description: 'a [class|="estateFacts"] div:nth-child(2) span | removeNewline | trim',
    rooms: 'a [data-test="rooms"] | removeNewline | trim',
    address: 'a [class|="estateFacts"] div span | removeNewline | trim'
  },
  paginate: '[class|="Pagination"] div button@href',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(immowelt)
