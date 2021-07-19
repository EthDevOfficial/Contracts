import BigNumber from "bignumber.js";
import { ONE, QUAD_GRAPHS, SWAP_FEE_ACTUAL1, SWAP_FEE_ACTUAL2, SWAP_FEE_SIMPLE_SUM, TRI_GRAPHS } from "./constants";
import { outFromIn } from "./helpers";
import { getSimpleImbalance, logSimpleTradeFromIn } from "./simpleHelpers";

export function logSimpleTradeCalcSlope(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
  swapFeePlus = new BigNumber(0),
  // inputStepProportion: BigNumber,
  // exactInputStep?: BigNumber
) {
  const initImbalance = getSimpleImbalance(R1a, R1b, R2a, R2b)
  const targetImbalance = SWAP_FEE_SIMPLE_SUM.plus(swapFeePlus)
  const input = initImbalance.minus(targetImbalance).multipliedBy(ONE.minus(initImbalance).dividedBy(targetImbalance))
  logSimpleTradeFromIn(
    'calc slope formula simple trade',
    input, R1a, R1b, R2a, R2b
  )
  return input
}

export function logSimpleTradeIterator(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
  initInputStepDivisor: BigNumber,
  maxIterations: number,
  threshold: BigNumber,
  swapFeePlus = new BigNumber(0),
  exactInitInputStep?: BigNumber
) {
  const initImbalance = getSimpleImbalance(R1a, R1b, R2a, R2b)
  let inputStep = exactInitInputStep ? exactInitInputStep : R1a.multipliedBy(initInputStepDivisor)
  let out1in2Step = outFromIn(inputStep, R1a, R1b, SWAP_FEE_ACTUAL1)
  let outputStep = outFromIn(out1in2Step, R2b, R2a, SWAP_FEE_ACTUAL2)
  let postStepImbalance = getSimpleImbalance(
    R1a.plus(inputStep),
    R1b.minus(out1in2Step),
    R2a.minus(outputStep),
    R2b.plus(out1in2Step)
  )
  for (let i = 0; i < maxIterations; i++) {
    inputStep = initImbalance.minus(SWAP_FEE_SIMPLE_SUM.plus(swapFeePlus)).multipliedBy(inputStep.dividedBy(initImbalance.minus(postStepImbalance)))
    out1in2Step = outFromIn(inputStep, R1a, R1b, SWAP_FEE_ACTUAL1)
    outputStep = outFromIn(out1in2Step, R2b, R2a, SWAP_FEE_ACTUAL2)
    postStepImbalance = getSimpleImbalance(
      R1a.plus(inputStep),
      R1b.minus(out1in2Step),
      R2a.minus(outputStep),
      R2b.plus(out1in2Step)
    )
    if (postStepImbalance.minus(SWAP_FEE_SIMPLE_SUM).absoluteValue().isLessThan(threshold)) {
      logSimpleTradeFromIn('iterative formula simple trade', inputStep, R1a, R1b, R2a, R2b)
      if (!TRI_GRAPHS && !QUAD_GRAPHS) console.log(`number of iterations: ${i + 1}`)
      return inputStep
    }
  }
  logSimpleTradeFromIn('iterative formula simple trade', inputStep, R1a, R1b, R2a, R2b)
  if (!TRI_GRAPHS && !QUAD_GRAPHS) console.log(`number of iterations (max): ${maxIterations}`)
  return inputStep
}