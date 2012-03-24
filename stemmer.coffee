exports.Stemmer = class Stemmer 
  step2list =
    ational: "ate"
    tional: "tion"
    enci: "ence"
    anci: "ance"
    izer: "ize"
    bli: "ble"
    alli: "al"
    entli: "ent"
    eli: "e"
    ousli: "ous"
    ization: "ize"
    ation: "ate"
    ator: "ate"
    alism: "al"
    iveness: "ive"
    fulness: "ful"
    ousness: "ous"
    aliti: "al"
    iviti: "ive"
    biliti: "ble"
    logi: "log"

  step3list =
    icate: "ic"
    ative: ""
    alize: "al"
    iciti: "ic"
    ical: "ic"
    ful: ""
    ness: ""

  c = "[^aeiou]"
  v = "[aeiouy]"
  C = c + "[^aeiouy]*"
  V = v + "[aeiou]*"
  mgr0 = "^(" + C + ")?" + V + C
  meq1 = "^(" + C + ")?" + V + C + "(" + V + ")?$"
  mgr1 = "^(" + C + ")?" + V + C + V + C
  s_v = "^(" + C + ")?" + v
  stem: (w) ->
    stem = undefined
    suffix = undefined
    firstch = undefined
    re = undefined
    re2 = undefined
    re3 = undefined
    re4 = undefined
    origword = w
    return w  if w.length < 3
    firstch = w.substr(0, 1)
    w = firstch.toUpperCase() + w.substr(1)  if firstch is "y"
    re = /^(.+?)(ss|i)es$/
    re2 = /^(.+?)([^s])s$/
    if re.test(w)
      w = w.replace(re, "$1$2")
    else w = w.replace(re2, "$1$2")  if re2.test(w)
    re = /^(.+?)eed$/
    re2 = /^(.+?)(ed|ing)$/
    if re.test(w)
      fp = re.exec(w)
      re = new RegExp(mgr0)
      if re.test(fp[1])
        re = /.$/
        w = w.replace(re, "")
    else if re2.test(w)
      fp = re2.exec(w)
      stem = fp[1]
      re2 = new RegExp(s_v)
      if re2.test(stem)
        w = stem
        re2 = /(at|bl|iz)$/
        re3 = new RegExp("([^aeiouylsz])\\1$")
        re4 = new RegExp("^" + C + v + "[^aeiouwxy]$")
        if re2.test(w)
          w = w + "e"
        else if re3.test(w)
          re = /.$/
          w = w.replace(re, "")
        else w = w + "e"  if re4.test(w)
    re = /^(.+?)y$/
    if re.test(w)
      fp = re.exec(w)
      stem = fp[1]
      re = new RegExp(s_v)
      w = stem + "i"  if re.test(stem)
    re = /^(.+?)(ational|tional|enci|anci|izer|bli|alli|entli|eli|ousli|ization|ation|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|logi)$/
    if re.test(w)
      fp = re.exec(w)
      stem = fp[1]
      suffix = fp[2]
      re = new RegExp(mgr0)
      w = stem + step2list[suffix]  if re.test(stem)
    re = /^(.+?)(icate|ative|alize|iciti|ical|ful|ness)$/
    if re.test(w)
      fp = re.exec(w)
      stem = fp[1]
      suffix = fp[2]
      re = new RegExp(mgr0)
      w = stem + step3list[suffix]  if re.test(stem)
    re = /^(.+?)(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ou|ism|ate|iti|ous|ive|ize)$/
    re2 = /^(.+?)(s|t)(ion)$/
    if re.test(w)
      fp = re.exec(w)
      stem = fp[1]
      re = new RegExp(mgr1)
      w = stem  if re.test(stem)
    else if re2.test(w)
      fp = re2.exec(w)
      stem = fp[1] + fp[2]
      re2 = new RegExp(mgr1)
      w = stem  if re2.test(stem)
    re = /^(.+?)e$/
    if re.test(w)
      fp = re.exec(w)
      stem = fp[1]
      re = new RegExp(mgr1)
      re2 = new RegExp(meq1)
      re3 = new RegExp("^" + C + v + "[^aeiouwxy]$")
      w = stem  if re.test(stem) or (re2.test(stem) and not (re3.test(stem)))
    re = /ll$/
    re2 = new RegExp(mgr1)
    if re.test(w) and re2.test(w)
      re = /.$/
      w = w.replace(re, "")
    w = firstch.toLowerCase() + w.substr(1)  if firstch is "y"
    w