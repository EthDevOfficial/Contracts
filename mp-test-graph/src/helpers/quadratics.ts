import BigNumber from "bignumber.js"

const TWO = new BigNumber(2)
const FOUR = new BigNumber(4)
const ZERO = new BigNumber(0)

export function quadraticSolPos(
  a: BigNumber,
  b: BigNumber,
  c: BigNumber
) {
  const toRoot = b.exponentiatedBy(2).minus(FOUR.multipliedBy(a).multipliedBy(c))
  if (toRoot.isGreaterThan(0)) {
    return toRoot.squareRoot().minus(b).dividedBy(TWO.multipliedBy(a))
  } else {
    return ZERO
  }
}

export function quadraticSolNeg(
  a: BigNumber,
  b: BigNumber,
  c: BigNumber
) {
  const toRoot = b.exponentiatedBy(2).minus(FOUR.multipliedBy(a).multipliedBy(c))
  if (toRoot.isGreaterThan(0)) {
    return toRoot.squareRoot().negated().minus(b).dividedBy(TWO.multipliedBy(a))
  } else {
    return ZERO
  }
}