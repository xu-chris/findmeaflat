const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  const size = o.size.split('Wohnfläche (ca.)')[1]
  const price = o.price
  const address = o.address
  const rooms = o.rooms.split('Zimmer')[1] + ' Zimmer'
  return Object.assign(o, { size, address, price, rooms })
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
    address: 'a [class|="estateFacts"] div span | removeNewline | trim',
    rooms: 'a [data-test="rooms"] | removeNewline | trim'
  },
  paginate: '.pagination #nlbPlus@href',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(immowelt)
