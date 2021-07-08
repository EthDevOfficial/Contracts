import { Fragment, ReactNode } from 'react'

function IfElse({ showIf, show, showElse }: {
  showIf: boolean
  show: ReactNode
  showElse: ReactNode
}) {
  return (
    <Fragment>
      {showIf ? show : showElse}
    </Fragment>
  )
}

export default IfElse