/**
goal : deduce the routing and the states of all modules 
this code load the two precendent tables *preStatesOfMods.tsv* and *modsConnections.tsv*
this code output one text file for the routing, and one table file for the modules states

ML 2016
*/

HashMap<String, Module> hm;
PrintWriter writer;
Table loadVarsMod, preStatesMods, modsConnections, statesMods;
StringList activMods, synths, routingChains, lastRouting, allDacs, toPrint;
StringDict abbr;
String evt;

void setup() {

  init();

  //1.iterate throw modsConnection ( the occurences of each var belonging to routing )
  for (int i=0; i <modsConnections.getRowCount(); i++) { 
    evt = modsConnections.getString(i, "evt"); //modConnections
    toPrint = new StringList();

    //2. find mods which are ON in preStatesMods Table
    activMods = new StringList();
    TableRow rowPreStatesMods = preStatesMods.findRow(evt, "evt");
    for (String title : preStatesMods.getColumnTitles() ) {
      if (rowPreStatesMods.getString(title).equals("1")) {
        if (title.equals("additive") || title.equals("chapo") || title.equals("paf")) activMods.append("osc"); // le groupe OSC
        else activMods.append(title);
      }
    }

    //3.do the 2nd check (nothing change for synth mods in fact) 
    for (String k : abbr.values()) hm.get(k).reset(); // reset for all mods 
    for (String v : activMods.values()) hm.get(v).setInputOutput(modsConnections.getString(i, v)); // for all activ mods add connections
    for (String v : activMods.values()) hm.get(v).treatWithoutInputs(); // remove treat with no input
    for (String v : activMods.values()) hm.get(v).deduceState(); 
    for (String v : activMods.values()) hm.get(v).removeDeadConnections();


    if (toPrint.size()>0) {
      println('\n'+evt);
      for (String v : toPrint.values())println(v);
      // printRouting();
    }


    //4 Export stateOfMods with the last state of mods
    TableRow newRow = statesMods.addRow();
    newRow.setString("evt", evt);
    for (int j=1; j< statesMods.getColumnCount(); j++) {
      String mod =statesMods.getColumnTitle(j);
      switch (mod) {
        case ("additive"):
        case ("chapo"):
        case ("paf"):
        if (hm.get("osc").state) {
          if (rowPreStatesMods.getString("additive").equals("1")) newRow.setInt("additive", 1); 
          if (rowPreStatesMods.getString("chapo").equals("1")) newRow.setInt("chapo", 1);
          if (rowPreStatesMods.getString("paf").equals("1")) newRow.setInt("paf", 1);
        }
        break;
      default :
        if ( hm.get(mod).state) newRow.setInt(j, 1);
        break;
      }
    }


    //5. find routing branch with the algorithm
    routingChains.clear();
    for (String k : synths.values()) if (hm.get(k).state) findRoutingChains(k);


    //6. add dacs to routingChains
    allDacs.clear();
    for (String v : activMods.values())if (!v.equals("spat") && hm.get(v).state && hm.get(v).dac) allDacs.append(v);
    allDacs.sort();
    if (allDacs.size()>0) routingChains.append("dac : "+allDacs.join(","));


    // 7. is there a change in the routing ? yes : export data
    boolean writeData = false;
    //println("equality ? "+'\t'+ compareStringList(lastRouting, routingChains));
    if (routingChains.size() == 0) continue; // if there is no branch, nor dac go ahead   
    if (lastRouting.size()==0) writeData = true; 
    else if (!compareStringLists(lastRouting, routingChains)) writeData = true;


    //8. write data if change occured
    if (writeData) {   
      writer.println('\n'+evt);
      for (String k : routingChains) writer.println(k);
      lastRouting = routingChains.copy();
    }
  }

  saveTable(statesMods, "statesOfMods.tsv");
  writer.flush(); 
  writer.close();
  exit();
}

///////////////////// VOIDS 
void findRoutingChains(String name) {
  StringList modsChain = new StringList();
  StringDict remain = new StringDict();
  boolean iterate = true; 
  String through;
  through = name;

  while ( iterate) {
    modsChain.append(through);
    //println('\t'+"itetrate through "+ through);
    String[] connectedMods = hm.get(through).outputs.array(); 

    switch( connectedMods.length ) {
      case (0):
      // one branch is found
      if(modsChain.size()>1) routingChains.appendUnique(modsChain.join(">"));
      //println('\t'+"new chain : "+modsChain.join(">"));

      if (remain.size() == 0) iterate = false; 
      else {
        //println('\t'+"rest keys are : "+join(remain.keyArray(), ","));
        //println("have to iterate throught :"+remain.get(remain.key(0)));
        modsChain.clear();

        // find mods which where connected to remain.key(0) & load them in modsChain
        for (int i=routingChains.size(); i >0; i--) {
          String[] cut = routingChains.get(i-1).split(">");
          for (int j=0; j< cut.length; j++) {
            if (cut[j].equals( remain.key(0))) {
              for (int k=0; k<j+1; k++) modsChain.append(cut[k]);
              i =0; // stop iteration through routingChains
              break;
            }
          }
        }
        //println("load this in modsChain :"+modsChain.join(">"));

        //update remain IntList
        String skippedMods = remain.get(remain.key(0)); 
        String cut [] = skippedMods.split(","); 
        through = cut[0]; 
        if (cut.length >1) {
          StringList temp = new StringList(); 
          for (int i=1; i< cut.length; i++) temp.append(cut[i]); 
          remain.set(remain.key(0), temp.join(","));
        } else remain.removeIndex(0); 

        iterate = true;
      }
      break; 

    default : 
      //if they are some outputs 
      StringList temp = new StringList(); //1.put other connection than the first one in a buffer
      for (int i = 1; i < connectedMods.length; i++) temp.append(connectedMods[i]); 
      if (temp.size()>0)remain.set(through, temp.join(",")); //2. attach through and this buffer in remain

      through = connectedMods[0]; // go through the very first connection
      iterate = true; 
      break;
    }
  }
}

boolean compareStringLists(StringList a, StringList b) {
  for (String s : a)  if (!b.hasValue(s))  return false;
  for (String s : b)  if (!a.hasValue(s))  return false;
  return true;
}


void init() {
  hm = new HashMap<String, Module>();
  writer = createWriter("routingChains.txt");
  abbr = new StringDict();
  synths = new StringList();
  routingChains = new StringList();  
  lastRouting = new StringList();
  allDacs = new StringList();
  statesMods = new Table();

  String [] column= {"evt", "sampler", "additive", "chapo", "paf", "reverb", "harm", "freqShift", "noise", "spat"};
  for (int i=0; i< column.length; i++)statesMods.addColumn(column[i]);

  preStatesMods = loadTable("../a_preStatesOfMods/preStatesOfMods.tsv", "header");
  modsConnections = loadTable("../b_modsConnections/modsConnection.tsv", "header");

  loadVarsMod = loadTable("modVars.txt", "tsv");

  for (int i=0; i< loadVarsMod.getRowCount(); i++) {
    String name = loadVarsMod.getString(i, 0);
    String abbreviation = loadVarsMod.getString(i, 1);
    String type =loadVarsMod.getString(i, 2);

    if (type.equals("synth"))  synths.append( name ); // create list of synths
    Module me = new Module(name, type); //instanciate Object
    hm.put(name, me); // put them into hashmap
    abbr.set(abbreviation, name); // create StringDict (n : noise),( t : sampler)
  }
}

void printRouting() {
  for (String v : activMods.values()) { 
    String temp =v ;
    if (hm.get(v).inputs.size() > 0)  temp += " in("+hm.get(v).inputs.join(",")+")";
    if (hm.get(v).outputs.size() > 0) temp += " out("+hm.get(v).outputs.join(",")+")";
    if (match(temp, " ") != null) println(temp);
  }
  //if (allDacs.size()>0) println("dac : "+allDacs.join(","));
  println('\n');
}


///CLASSE
class Module {
  String name, type; 
  StringList inputs, outputs; 
  boolean dac, state ;

  Module(String n, String t) {
    name = n; 
    type = t;
  }

  void reset() {
    state = false; 
    dac = false;
    outputs = new StringList();
    inputs = new StringList();
  }

  void setInputOutput(String in) {
    if (!in.equals("null") && ! in.isEmpty() ) {
      String [] cut = splitTokens(in, " ,");
      for (int i=0 ; i< cut.length ; i++) {
        String destination = cut[i].substring(3, 4); // get destination
        if ( destination.equals("2") ) dac = true; // set dac connection
        else {
          outputs.append( abbr.get(destination)) ; // add outputs
          hm.get(abbr.get(destination)).inputs.append(name); // add inputs
        }
      }
    }
  }

  
  void treatWithoutInputs() {  
    if (type.equals("treat")) {
      // if treat mods have no input, then remove all output (dac & outputs)
      if (inputs.size() == 0) {  
        for (String k : outputs.values()) hm.get(k).inputs.removeValue(name); 
        outputs.clear();
        dac = false;
        toPrint.append(name+" has no inputs");
      }
    }
  }


  void deduceState() {
    if (outputs.size() >0 || dac ) state = true;
    if (name.equals("spat") && inputs.size()>0 ) state = true;
  }
  void removeDeadConnections(){
   for(String v : outputs) if( !hm.get(v).state) outputs.removeValue(v); 
  }
}