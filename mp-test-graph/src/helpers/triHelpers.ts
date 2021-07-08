import BigNumber from "bignumber.js"
import { NUM_DECIMALS, ONE, SWAP_FEE_ACTUAL1, SWAP_FEE_ACTUAL2, SWAP_FEE_ACTUAL3, SWAP_FEE_TRI_SUM, TRI_GRAPHS } from "./constants"
import { inFromOut, inverse, linspace, outFromIn, productOf, sumOf } from "./helpers"
import { outputForTargetMP } from "./moveToTarget"

const log = console.log

export function logTriTrade(
  title: string,
  input: BigNumber,
  out1in2: BigNumber,
  out2in3: BigNumber,
  output: BigNumber,
  R1aPost: BigNumber,
  R1bPost: BigNumber,
  R2bPost: BigNumber,
  R2cPost: BigNumber,
  R3cPost: BigNumber,
  R3aPost: BigNumber,
) {
  if (TRI_GRAPHS) {
    log(title)
    log(`diff: ${output.minus(input).toFixed(NUM_DECIMALS)}`)
    log(`input: ${input.toFixed(NUM_DECIMALS)}`)
    // log(`out 1 in 2: ${out1in2.toFixed(NUM_DECIMALS)}`)
    // log(`out 2 in 3: ${out2in3.toFixed(NUM_DECIMALS)}`)
    log(`imbalance: ${getTriImbalance(R1aPost, R1bPost, R2bPost, R2cPost, R3cPost, R3aPost).toFixed(NUM_DECIMALS)}`)
    log()
  }
  
}

export function logTriTradeFrom1(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
) {
  // gets the diff using optimal on 1st corner
  // const multiplier = getTriMultiplier(R1a, R1b, R2b, R2c, R3c, R3a)
  const targetMP = getTriTargetMP(R1a, R1b, R2b, R2c, R3c, R3a)
  const out1in2PreMul = outputForTargetMP(R1a, R1b, targetMP, SWAP_FEE_ACTUAL1)
  const input = inFromOut(out1in2PreMul, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out1in2 = outFromIn(input, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2in3 = outFromIn(out1in2, R2b, R2c, SWAP_FEE_ACTUAL2)
  const output = outFromIn(out2in3, R3c, R3a, SWAP_FEE_ACTUAL3)
  logTriTrade(
    'trade using corner 1', 
    input,
    out1in2,
    out2in3,
    output,
    R1a.plus(input),
    R1b.minus(out1in2),
    R2b.plus(out1in2),
    R2c.minus(out2in3),
    R3c.plus(out2in3),
    R3a.minus(output)
  )
  return input
}

export function logTriTradeFrom2(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
) {
  // gets the diff using optimal on 1st corner
  // const multiplier = getTriMultiplier(R1a, R1b, R2b, R2c, R3c, R3a)
  const targetMP = getTriTargetMP(R2b, R2c, R3c, R3a, R1a, R1b)
  const out2in3 = outputForTargetMP(R2b, R2c, targetMP, SWAP_FEE_ACTUAL2)
  const out1in2 = inFromOut(out2in3, R2b, R2c, SWAP_FEE_ACTUAL2)
  const input = inFromOut(out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  const output = outFromIn(out2in3, R3c, R3a, SWAP_FEE_ACTUAL3)
  logTriTrade(
    'trade using corner 2', 
    input,
    out1in2,
    out2in3,
    output,
    R1a.plus(input),
    R1b.minus(out1in2),
    R2b.plus(out1in2),
    R2c.minus(out2in3),
    R3c.plus(out2in3),
    R3a.minus(output)
  )
  return input
}

export function logTriTradeFrom3(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
) {
  // gets the diff using optimal on 1st corner
  // const multiplier = getTriMultiplier(R1a, R1b, R2b, R2c, R3c, R3a)
  const targetMP = getTriTargetMP(R3c, R3a, R1a, R1b, R2b, R2c)
  const outputPreMul = outputForTargetMP(R3c, R3a, targetMP, SWAP_FEE_ACTUAL3)
  const out2in3 = inFromOut(outputPreMul, R3c, R3a, SWAP_FEE_ACTUAL3)
  const output = outFromIn(out2in3, R3c, R3a, SWAP_FEE_ACTUAL3)
  const out1in2 = inFromOut(out2in3, R2b, R2c, SWAP_FEE_ACTUAL2)
  const input = inFromOut(out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  logTriTrade(
    'trade using corner 3', 
    input, out1in2, out2in3, output,
    R1a.plus(input),
    R1b.minus(out1in2),
    R2b.plus(out1in2),
    R2c.minus(out2in3),
    R3c.plus(out2in3),
    R3a.minus(output)
  )
  return input
}

export function logTriTradeFromIn(
  title: string,
  input: BigNumber,
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
) {
  const out1in2 = outFromIn(input, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2in3 = outFromIn(out1in2, R2b, R2c, SWAP_FEE_ACTUAL2)
  const output = outFromIn(out2in3, R3c, R3a, SWAP_FEE_ACTUAL3)
  logTriTrade(
    title,
    input, out1in2, out2in3, output,
    R1a.plus(input),
    R1b.minus(out1in2),
    R2b.plus(out1in2),
    R2c.minus(out2in3),
    R3c.plus(out2in3),
    R3a.minus(output)
  )
  return output.minus(input)
}

export function getTriTargetMP(
  R1a: BigNumber, 
  R1b: BigNumber,
  R2b: BigNumber, 
  R2c: BigNumber,
  R3c: BigNumber, 
  R3a: BigNumber
) {
  const cornerMP = R1a.dividedBy(R1b)
  const oppMP1 = R2b.dividedBy(R2c)
  const oppMP2 = R3c.dividedBy(R3a)
  const oppMP = getTriOppositeRatio(oppMP1, oppMP2)
  const dif = oppMP.minus(cornerMP)
  const total = sumOf(R1a, R1b, R2b, R2c, R3c, R3a)
  const C = ONE.minus(R1a.plus(R1b).dividedBy(total))
  console.log(`C: ${C}`)
  return cornerMP.plus(dif.multipliedBy(C))
}

export function getTriTargetMPGivenC(
  R1a: BigNumber, 
  R1b: BigNumber,
  R2b: BigNumber, 
  R2c: BigNumber,
  R3c: BigNumber, 
  R3a: BigNumber,
  C: number // between 0 and 1
) {
  const cornerMP = R1a.dividedBy(R1b)
  const oppMP1 = R2b.dividedBy(R2c)
  const oppMP2 = R3c.dividedBy(R3a)
  const oppMP = getTriOppositeRatio(oppMP1, oppMP2)
  const dif = oppMP.minus(cornerMP)
  return cornerMP.plus(dif.multipliedBy(C))
}

export function getTriOppositeRatio(MPbc: BigNumber, MPca: BigNumber) {
  return inverse(MPbc.multipliedBy(MPca))
}

export function getTriImbalanceSub(
  MPab: BigNumber,
  MPbc: BigNumber,
  MPca: BigNumber
) {
  // inverse because MPbc * MPca ~= MPba, want MPab to match units
  return getTriOppositeRatio(MPbc, MPca).minus(MPab)
}

export function getTriImbalance(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
) {
  const MPba = R1b.dividedBy(R1a)
  const MPcb = R2c.dividedBy(R2b)
  const MPac = R3a.dividedBy(R3c)
  return productOf(MPba, MPac, MPcb).minus(1)
}

export function logTriTradeChooseCorner(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber
) {
  // return logTriTradeFrom1(R1a, R1b, R2b, R2c, R3c, R3a)
  switch (chooseCorner(R1a, R1b, R2b, R2c, R3c, R3a)) {
    case 1:
      return logTriTradeFrom1(R1a, R1b, R2b, R2c, R3c, R3a)
    case 2:
      return logTriTradeFrom2(R1a, R1b, R2b, R2c, R3c, R3a)
    case 3:
      return logTriTradeFrom3(R1a, R1b, R2b, R2c, R3c, R3a)
  }
}

export function getTriTradeLineFromInputRange(
  range: [BigNumber, BigNumber],
  length: number,
  reducer: number,
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber
) {
  const line = linspace(
    range[0].dividedBy(reducer).toNumber(),
    range[1].dividedBy(reducer).toNumber(),
    length 
  )
  return line.map(inputPreMul => getTriTradeFromIn(
    new BigNumber(inputPreMul).multipliedBy(reducer),
    R1a, R1b, R2b, R2c, R3c, R3a
  ))
}

function getTriTradeFromIn(
  input: BigNumber,
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
  reducer = 1
) {
  const out1in2 = outFromIn(input, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2in3 = outFromIn(out1in2, R2b, R2c, SWAP_FEE_ACTUAL2)
  const output = outFromIn(out2in3, R3c, R3a, SWAP_FEE_ACTUAL3)
  return {
    input: Math.floor(input.dividedBy(reducer).toNumber()),
    diff: Math.floor(output.minus(input).dividedBy(reducer).toNumber()),
    imbalance: getTriImbalance(
      R1a.plus(input),
      R1b.minus(out1in2),
      R2b.plus(out1in2),
      R2c.minus(out2in3),
      R3c.plus(out2in3),
      R3a.minus(output)
    ).toNumber(),
  }
} 

export function chooseCorner(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
) {
  if (R1b.isLessThan(R2b)) {
    if (R1a.isLessThan(R3a)) {
      // pool 1 lowest liq
      return 1
    } else {
      // pool 3 lowest liq
      return 3
    }
  } else {
    // pool 2 or pool 3 lowest liq
    if (R2c.isLessThan(R3c)) {
      return 2
    } else {
      return 3
    }
  }
}

export function getTriMultiplier(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
  swapFeeAdd = 0
) {
  return ONE.minus(SWAP_FEE_TRI_SUM.plus(swapFeeAdd).dividedBy(getTriImbalance(R1a, R1b, R2b, R2c, R3c, R3a)))
}