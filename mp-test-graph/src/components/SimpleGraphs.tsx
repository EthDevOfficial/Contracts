import BigNumber from "bignumber.js"
import { Fragment } from "react"
import { TRI_GRAPHS } from "../helpers/constants"
import { getSimpleImbalance, getSimpleTradeLineFromInputRange } from "../helpers/simpleHelpers"
import { logSimpleTradeIterator } from "../helpers/simpleHelpersLowImb"
import Graph from './Graph'

const IMBALANCE = .0062

const R1in = new BigNumber('833278512869163330674731')
const R1out = new BigNumber('2038188010304541813540')

// const R2in = new BigNumber('21880839199025783')
const R2out = new BigNumber('9016371641490658451') 

const R2in = R2out.multipliedBy(R1out.dividedBy(R1in.plus(R1in.multipliedBy(IMBALANCE))))

if (!TRI_GRAPHS) console.log(`init imbalance: ${getSimpleImbalance(R1in, R1out, R2out, R2in)}`)

const inputStepProportion = new BigNumber(1).dividedBy('1000000000')
// const inputFromCalcSlope = logSimpleTradeCalcSlope(
//   R1in, R1out, R2out, R2in,
//   inputStepProportion,
//   // new BigNumber('10000')
// )

// const range1 = inputFromCalcSlope
// const data1 = getSimpleTradeLineFromInputRange(
//   [inputFromCalcSlope.minus(range1), inputFromCalcSlope.plus(range1)], // range
//   100,  // number of values (resolution)
//   100000, // divisor to convert BN to normal numbers
//   R1in, R1out, R2out, R2in
// )

// if (!TRI_GRAPHS) {
//   console.log(`simple calc slope formula input: ${inputFromCalcSlope.toString()}`)
//   console.log()
// }

const MAX_ITERATIONS = 10
const CLOSENESS_THRESHOLD = new BigNumber('.0003')
const inputFromIterator = logSimpleTradeIterator(
  R1in, R1out, R2out, R2in,
  inputStepProportion,
  MAX_ITERATIONS, 
  CLOSENESS_THRESHOLD,
  new BigNumber('.000025') // swap Fee plus (ie .006 + .000025)
  // new BigNumber('10000')
)

const range2 = inputFromIterator
const data2 = getSimpleTradeLineFromInputRange(
  [inputFromIterator.minus(range2), inputFromIterator.plus(range2)], // range
  100,  // number of values (resolution)
  100000, // divisor to convert BN to normal numbers
  R1in, R1out, R2out, R2in
)

// if (!TRI_GRAPHS) {
//   console.log(`simple iterator formula input: ${inputFromIterator.toString()}`)
//   console.log()
// }

function SimpleGraphs() {
  return (
    <Fragment>
      {/* <Graph
        title="diff from calc slope"
        data={data1}
        lineDataKey="diff"
        xAxisDataKey="input"
        verticalX={inputFromCalcSlope.toFixed(0)}
        tooltip
      /> */}
      {/* <Graph
        title="imbalance from calc slope"
        data={data1}
        lineDataKey="imbalance"
        xAxisDataKey="input"
        tooltip
      /> */}
      <Graph
        title="revenue from iterator"
        data={data2}
        lineDataKey="diff"
        xAxisDataKey="input"
        verticalX={inputFromIterator.toFixed(0)}
        tooltip
      />
      {/* <Graph
        title="imbalance from iterator"
        data={data2}
        lineDataKey="imbalance"
        xAxisDataKey="input"
        verticalX={inputFromIterator.toFixed(0)}
        tooltip
      /> */}
    </Fragment>
  );
}

export default SimpleGraphs