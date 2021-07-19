import BigNumber from "bignumber.js"
import { Fragment } from "react"
import { NUM_DECIMALS, QUAD_GRAPHS } from "../helpers/constants"
import { productOf } from "../helpers/helpers"
import { getQuadImbalance, getQuadTradeLineFromInputRange, logQuadTradeIterator } from "../helpers/quadHelpers"
import Graph from './Graph'

const IMBALANCE = .033

const R1a = new BigNumber('404584745298155753883610')
const R1b = new BigNumber('212554887870712086452')

const R2b = new BigNumber('2682842743467141')
const R2c = new BigNumber('26991751260276137')

const R3c = new BigNumber('1306339061991646870918')
const R3d = new BigNumber('252225412223448634367636')

const R4d = new BigNumber('252225412223448634367')
// const R4a = new BigNumber('252225412223448634367636')
const R4a = productOf(R1a.dividedBy(R1b), R2b.dividedBy(R2c), R3c.dividedBy(R3d), new BigNumber(1 + IMBALANCE), R4d)

if (QUAD_GRAPHS) console.log(`init imbalance: ${getQuadImbalance(R1a, R1b, R2b, R2c, R3c, R3d, R4d, R4a).toFixed(NUM_DECIMALS)}`)

const inputStepDivisor = new BigNumber('100000')
const CLOSENESS_THRESHOLD = new BigNumber('.00005')
const RANGE_MULTIPLIER = 1

const MAX_ITERATIONS = 3
const inputFromIterator = logQuadTradeIterator(
  R1a, R1b, R2b, R2c, R3c, R3d, R4d, R4a,
  inputStepDivisor, 
  MAX_ITERATIONS,
  CLOSENESS_THRESHOLD,
  new BigNumber('0.000054')
)

const data = getQuadTradeLineFromInputRange(
  [
    inputFromIterator.minus(inputFromIterator.multipliedBy(RANGE_MULTIPLIER)), 
    inputFromIterator.plus(inputFromIterator.multipliedBy(RANGE_MULTIPLIER))
  ], // range
  100,  // number of values (resolution)
  100000, // divisor to convert BN to normal numbers
  R1a, R1b, R2b, R2c, R3c, R3d, R4d, R4a
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
        data={data}
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