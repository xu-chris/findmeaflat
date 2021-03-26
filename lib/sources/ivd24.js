const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  console.log(o)
  const price = o.price.split(' | ')[1]
  const size = o.price.split(' | ')[0]
  return { ...o, price, size }
}

function applyBlacklist(o) {
  const titleNotBlacklisted = !utils.isOneOf(o.title, config.blacklist)
  const descNotBlacklisted = !utils.isOneOf(o.description, config.blacklist)
  const wantedDistrict = utils.isOneOf(o.description, config.wantedDistricts)

  return wantedDistrict && titleNotBlacklisted && descNotBlacklisted
}

const enabled = !!config.providers.ivd24

const ivd24 = {
  name: 'ivd24',
  enabled,
  url: !enabled || config.providers.ivd24.url,
  crawlContainer: '.data-container .result',
  crawlFields: {
    id: '.result@data-id | int',
    price: '.row.no-gutters div span | removeNewline | trim',
    size: '.row.no-gutters div span | removeNewline | trim',
    title: '.result-content h2 | removeNewline | trim',
    link: '.expose-button a@href | removeNewline | trim',
    address: '.result-content h5 | removeNewline | trim',
    radius_distance: '.result-content p | removeNewline | trim'
  },
  paginate: '.paginationjs-pages .pagination-next@href',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(ivd24)
