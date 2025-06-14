const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  return { ...o }
}

function applyBlacklist(o) {
  const titleNotBlacklisted = !utils.isOneOf(o.title, config.blacklist)
  const descNotBlacklisted = !utils.isOneOf(o.description, config.blacklist)
  const wantedDistrict = utils.isOneOf(o.description, config.wantedDistricts)

  return wantedDistrict && titleNotBlacklisted && descNotBlacklisted
}

const enabled = !!config.providers.kleinanzeigen
const kleinanzeigen = {
  name: 'kleinanzeigen',
  enabled,
  url: !enabled || config.providers.kleinanzeigen.url,
  crawlContainer: '#srchrslt-adtable .ad-listitem',
  crawlFields: {
    id: '.aditem@data-adid | int',
    price: '.aditem-main--middle--price | removeNewline | trim',
    size:
      '.aditem-main--bottom p span:nth-child(1) | removeNewline | trim',
    title: '.aditem-main .text-module-begin a | removeNewline | trim',
    link: '.aditem-main .text-module-begin a@href | removeNewline | trim',
    description: '.aditem-main--middle--description | removeNewline | trim',
    address: '.aditem-main--top--left | removeNewline | trim',
    rooms: '.aditem-main--bottom p span:nth-child(2) | removeNewline | trim',
  },
  paginate: '#srchrslt-pagination .pagination-next@href',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(kleinanzeigen, { debugRawHtml: config.debugRawHtml })
