const rules: Record<string, { terms: string[]; weight: number }[]> = {
  'Economy & Jobs': [{ terms: ['economy','employment','jobs','gdp','inflation'], weight: 2 }],
  'Agriculture & Rural India': [{ terms: ['farmer','agriculture','crop','rural'], weight: 2 }],
  'Healthcare': [{ terms: ['health','hospital','vaccine','medical'], weight: 2 }],
  'Education': [{ terms: ['education','school','university','student'], weight: 2 }],
  'Foreign Affairs': [{ terms: ['diplomacy','bilateral','international','summit'], weight: 2 }],
  'Festivals & Greetings': [{ terms: ['wishes','festival','greetings'], weight: 1.5 }],
}
export function classify(text: string) {
  const content = text.toLocaleLowerCase(); const scores = Object.entries(rules).map(([category, groups]) => ({ category, score: groups.reduce((sum,g) => sum + g.terms.filter(t => content.includes(t)).length*g.weight, 0) })).sort((a,b)=>b.score-a.score)
  const best=scores[0]; const confidence = best?.score ? Math.min(.95, .5 + best.score/10) : .2
  return { category: best?.score ? best.category : 'Other', confidence, level: confidence >= .9 ? 'high' : confidence >= .6 ? 'medium' : 'needs review', manualReviewRequired: confidence < .6 }
}
export function extractMetadata(text:string) { const hashtags=[...text.matchAll(/#([\p{L}\p{N}_]+)/gu)].map(x=>x[1]); const mentions=[...text.matchAll(/@([\w]+)/g)].map(x=>x[1]); const containsClaim=/\b\d+(?:\.\d+)?%?|\b(announced|increased|decreased|launched)\b/i.test(text); return { hashtags, mentions, keywords: text.toLowerCase().match(/[\p{L}]{5,}/gu)?.slice(0,12) ?? [], containsClaim, claimType: containsClaim ? (/\d/.test(text)?'Statistical claim':'Other verifiable claim') : null } }
