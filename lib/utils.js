function isOneOf(word, arr = []) {
  const expression = String.raw`\b(${arr.join('|')})\b`
  const blacklist = new RegExp(expression, 'ig')

  return blacklist.test(word)
}

function smallerEquals(int, reference) {
  if (int != undefined && reference != undefined) {
    return int <= reference
  }
  else return true
}

function shorten(str, len = 30) {
  if (str && str.length)
    return str.length > len ? str.substring(0, len) + '...' : str
}

function objectToQuerystring(obj) {
  return Object.keys(obj).reduce((str, key, i) => {
    const delimiter = i === 0 ? '?' : '&'
    const k = encodeURIComponent(key)
    const v = encodeURIComponent(obj[key])
    return [str, delimiter, k, '=', v].join('')
  }, '')
}

function filterNonNullables(array) {
  return array.filter(v => v);
}

function combineWhenGiven(prefix, data, separator) {
  if (data !== undefined )
    return prefix + ' ' + data + separator
  else
    return ""
}

function random(min, max) {
  return Math.round(Math.random() * (max - min) + min)
}

function extractUrlFromJavaScript(jsString) {
  if (!jsString) return ''

  // Fallback: try to extract any HTTPS URL from the string
  urlMatch = jsString.match(/https:\/\/[^'",\s)]+/)
  return urlMatch ? urlMatch[0] : jsString
}

module.exports = { isOneOf, smallerEquals, shorten, objectToQuerystring, filterNonNullables, combineWhenGiven, random, extractUrlFromJavaScript }
