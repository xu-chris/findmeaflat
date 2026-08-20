const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  const address = o.address.split(' • ')[0]
  const price = o.price.split('€ ')[1].split(',-')[0] + ' €'
  const id = parseInt(o.id)

  // Extract URL from JavaScript tracking code
  const link = utils.extractUrlFromJavaScript(o.link)

  const rooms = o.rooms + ' Zimmer'
  return { ...o, address, id, price, link, rooms }
}

function applyBlacklist(o) {
  const titleNotBlacklisted = !utils.isOneOf(o.title, config.blacklist)
  const descNotBlacklisted = !utils.isOneOf(o.description, config.blacklist)

  return titleNotBlacklisted && descNotBlacklisted
}


const enabled = !!config.providers.immosuchmaschine
const immosuchmaschine = {
  name: 'immosuchmaschine',
  enabled,
  url: !enabled || config.providers.immosuchmaschine.url,
  crawlContainer: '.result-list li',
  crawlFields: {
    id: '.data_title div@data-expose-id | removeNewline | trim',
    price: '.data_price span | removeNewline | trim',
    size:
      '.data_size dd | removeNewline | trim',
    title: '.data_title div.objectLink | removeNewline | trim',
    link: '.data_title div.objectLink@data-js | removeNewline | trim',
    description: '.data_desc span | removeNewline | trim',
    address: '.data_zipcity | removeNewline | trim',
    rooms: '.data_rooms dd | removeNewline | trim',
  },
  paginate: '.link.next@data-href',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(immosuchmaschine, { debugRawHtml: config.debugRawHtml })
