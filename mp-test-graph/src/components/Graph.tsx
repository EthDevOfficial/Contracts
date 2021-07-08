import { CartesianGrid, Line, LineChart, ResponsiveContainer, XAxis, YAxis, Tooltip, ReferenceLine } from 'recharts'

interface GraphProps {
  title: string,
  data: object[]
  lineDataKey: string,
  xAxisDataKey?: string,
  grid?: boolean
  tooltip?: boolean,
  lineType?: 'monotone' | 'linear' | 'step',
  verticalX?: number | string,
  verticalXLabel?: string
}

function Graph({ title, data, lineDataKey, xAxisDataKey, lineType, grid, tooltip, verticalX, verticalXLabel } : GraphProps) {
  return (
    <div className="GraphContainer">
      <div style={{ fontSize: "1.5rem", marginBottom: "0.5rem" }}>
        {" "}
        {title}{" "}
      </div>
      <ResponsiveContainer width="90%" height="90%">
        <LineChart
          margin={{ top: 5, right: 10, bottom: 5, left: 5 }}
          data={data}
        >
          <Line
            type={lineType ? lineType : "monotone"}
            dataKey={lineDataKey}
            dot={{ fill: "#21A179" }}
          />
          <XAxis type="number" dataKey={xAxisDataKey} />
          <YAxis />
          {grid && <CartesianGrid stroke="#ccc" strokeDasharray="5 5" />}
          {tooltip && <Tooltip />}
          {verticalX && (
            <ReferenceLine
              x={verticalX}
              stroke="#990D35"
              label={verticalXLabel}
              width='2px'
            />
          )}
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

export default Graph
