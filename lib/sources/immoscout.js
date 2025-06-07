const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  const title = o.title.replace('<span class="gallery-tag indicator indicator--brand new-flag-tag margin-right-xs"><span>NEU</span></span>', '')
  const address = (o.address || '').replace(/\(.*\),.*$/, '').trim()
  const link = "https://immobilienscout24.de" + o.link

  return Object.assign(o, { title, address, link })
}

function applyBlacklist(o) {
  return !utils.isOneOf(o.title, config.blacklist)
}

const enabled = !!config.providers.immoscout

const immoscout = {
  name: 'immoscout',
  enabled,
  url: !enabled || config.providers.immoscout.url,
  crawlContainer: '#resultListItems .result-list__listing',
  crawlFields: {
    id: '.result-list-entry@data-obid | int',
    price:
      '.result-list-entry .result-list-entry__primary-criterion .grid-item:first-child dd | removeNewline | trim | int',
    size:
      '.result-list-entry .result-list-entry__primary-criterion .grid-item:nth-child(2) dd | removeNewline | trim | int',
    title:
      '.result-list-entry .result-list-entry__brand-title | removeNewline | trim',
    rooms:
      '.result-list-entry .result-list-entry__primary-criterion .grid-item:nth-child(3) dd span | removeNewline | trim | int',
    link: '.result-list-entry .result-list-entry__brand-title-container@href',
    address: '.result-list-entry__address span',
  },
  paginate: '.pagination [data-testid="pagination-button-next"]',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(immoscout, { debugRawHtml: config.debugRawHtml })
