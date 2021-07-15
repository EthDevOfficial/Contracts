import BigNumber from "bignumber.js"
import { Fragment } from "react"
import { NUM_DECIMALS, TRI_GRAPHS } from "../helpers/constants"
import { productOf } from "../helpers/helpers"
import { getTriImbalance, getTriTradeLineFromInputRange } from "../helpers/triHelpers"
import { logTriTradeIterator } from "../helpers/triHelpersLowImb"
import Graph from './Graph'

const IMBALANCE = .0092

const R1a = new BigNumber('404584745298155753883610')
const R1b = new BigNumber('212554887870712086452')

const R2b = new BigNumber('2682842743467141')
const R2c = new BigNumber('26991751260276137')

const R3c = new BigNumber('1306339061991646870918')
// const R3a = productOf(R1a.dividedBy(R1b), R2b.dividedBy(R2c), new BigNumber(1 + IMBALANCE), R3c)
const R3a = new BigNumber('252225412223448634367636')

if (TRI_GRAPHS) console.log(`init imbalance: ${getTriImbalance(R1a, R1b, R2b, R2c, R3c, R3a).toFixed(NUM_DECIMALS)}`)

const inputStepDivisor = new BigNumber('100000')
const CLOSENESS_THRESHOLD = new BigNumber('.00005')
const RANGE_MULTIPLIER = 1

// const inputFromOneStep = logTriTradeIterator(
//   R1a, R1b, R2b, R2c, R3c, R3a,
//   inputStepDivisor,
//   1,
//   CLOSENESS_THRESHOLD,
//   new BigNumber('.000054')
// )
// const data1 = getTriTradeLineFromInputRange(
//   [
//     inputFromOneStep.minus(inputFromOneStep.multipliedBy(RANGE_MULTIPLIER)), 
//     inputFromOneStep.plus(inputFromOneStep.multipliedBy(RANGE_MULTIPLIER))
//   ], // range
//   100,  // number of values (resolution)
//   100000, // divisor to convert BN to normal numbers
//   R1a, R1b, R2b, R2c, R3c, R3a
// )

const MAX_ITERATIONS = 3
const inputFromIterator = logTriTradeIterator(
  R1a, R1b, R2b, R2c, R3c, R3a,
  inputStepDivisor, 
  MAX_ITERATIONS,
  CLOSENESS_THRESHOLD,
  new BigNumber('0.000054')
)

const data2 = getTriTradeLineFromInputRange(
  [
    inputFromIterator.minus(inputFromIterator.multipliedBy(RANGE_MULTIPLIER)), 
    inputFromIterator.plus(inputFromIterator.multipliedBy(RANGE_MULTIPLIER))
  ], // range
  100,  // number of values (resolution)
  100000, // divisor to convert BN to normal numbers
  R1a, R1b, R2b, R2c, R3c, R3a
)

function TriGraphs() {
  return (
    <Fragment>
      {/* <Graph
        title='diff from 1 step' 
        data={data1}
        lineDataKey="diff"
        xAxisDataKey='input'
        tooltip
      /> */}
      {/* <Graph 
        title='imbalance from 1 step'
        data={data1} 
        lineDataKey="imbalance"
        xAxisDataKey='input'
        tooltip
      /> */}
      <Graph
        title='revenue from iterator' 
        data={data2}
        lineDataKey="diff"
        xAxisDataKey='input'
        verticalX={inputFromIterator.toFixed(0)}
        tooltip
      />
      {/* <Graph 
        title='imbalance from iterator'
        data={data2} 
        lineDataKey="imbalance"
        xAxisDataKey='input'
        tooltip
      /> */}
    </Fragment>
  )
}

export default TriGraphs