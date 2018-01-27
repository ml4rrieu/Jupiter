class Module {
  HashMap <String, DictList> vv;
  String name, type, state; 
  StringList vars, buffer;

  Module(String _name, String _type, String var) {
    vv = new HashMap <String, DictList>();
    buffer = new StringList();
    vars = new StringList();
    name = _name; 
    type = _type;
    state="0";

    String[] cut = splitTokens(var, " ,");
    cut = trim(cut);
    for (int i=0; i< cut.length; i++) {
      vars.append(cut[i]);
      DictList me = new DictList();
      vv.put(cut[i], me);
    }
  }

  void memorize(String var, String value) {
    buffer.append(var);
    vv.get(var).list.append(abs(int(value)));
  }

  void deduceState() {
    //l'Ã©tat du module est stockÃ© dans la var *state*

    if (type.equals("treat") && buffer.size() == 0 ) state="last"; // if no occurrence happened
    if (buffer.size()> 0) { // if occurence happened

      //zoom in : aller du module Ã  ces cannaux
      for (String k : vars.values()) { // iterate throw channel vars and save state in *result*
        if (vv.get(k).list.size()>0) vv.get(k).deduce();
      }

      //vÃ©rifier ttes les vars des modules
      int multiVarSum=0; 
      for (String k : vars.values())  multiVarSum += vv.get(k).result;
      state = (multiVarSum >0) ? "1" : "0"; // come back (zoom out) to module level
      //println('\t'+name+" "+state);
    }
  }

  void writeState() {
    int lastRow = table.lastRowIndex(); 

    switch (state) {
    case "last" : 
      if (lastRow == 0 ) table.setInt(lastRow, name, 0);  // for the first evt
      else table.setInt(lastRow, name, table.getInt(lastRow-1, name) ); // repeat last value
      break; 
    case "1" : 
      table.setInt(lastRow, name, 1); 
      break; 
    case "0" : 
      table.setInt(lastRow, name, 0); 
      break;
    }
  }

  void printVars() {
    StringList temp = new StringList();
    for (String k : vars.values() ) {
      if (vv.get(k).list.size()>0)  temp.append(vv.get(k).list.join(" "));
    }
    if (temp.size()>0) println(join(temp.values(), " "));
  }


  class DictList {
    IntList list; 
    int result; 

    DictList() {
      list = new IntList();
    }

    void deduce() { // deduce vars general values from her occurrence
      if (list.size()>0) {
        if (list.max() > 0) result = 1; // if there is one occurrence > 0  
        if (list.max() == 0) result = 0; // if all occurrences are 0  
        // println(name+" "+">result = "+result);
      }
      list.clear();
    }
  }
}
