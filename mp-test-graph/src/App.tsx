import './App.css'
import IfElse from './components/IfElse';
import SimpleGraphs from './components/SimpleGraphs'
import TriGraphs from './components/TriGraphs'
import { TRI_GRAPHS } from './helpers/constants';

function App() {
  return (
    <div className="App">
      <div className="Topbar"> {TRI_GRAPHS ? 'Tri MP Test' : 'Simple MP Test'} </div>
      <div className="Graphs">
        <IfElse 
          showIf={TRI_GRAPHS}
          show={<TriGraphs />}
          showElse={<SimpleGraphs/>}
        />
      </div>
    </div>
  );
}

export default App;
