/**
for each evt, and for each modules, put outputs (where signals are going) inside table
to2 mean stereo connection
to4 mean spat connection

 ML 2016 
 */
import java.util.Map;
HashMap<String, Module> hm;
Table table, routVars; 
StringList var2catch;
int section, evt, readingEvt;
boolean load; 
String path;


void setup() {

  init();

  for (section = 1; section < 14; section ++) {
    if (section < 10 ) path = "../../../../myJupiter/rebuildPatch/score/section0"+section+"-qlist.txt" ;
    if (section >=10) path =    "../../../../myJupiter/rebuildPatch/score/section"+section+"-qlist.txt" ;
    String[] score = loadStrings(path);

    //0. ITERATE TRHOW SCORE
    evt = 0;
    for (int i=0; i< score.length; i++) { //score.length
      String [] cutLine = splitTokens(score[i], " ,;");

      //1. filter process : escape undesired lines & find indexValue
      if ( cutLine[0].equals("comment")) continue;
      int tempRemoveNumber = 0;
      for (int j=0; j<cutLine.length; j++ ) if (!isItANumber(cutLine[j])) tempRemoveNumber+=1 ;
      if (tempRemoveNumber == 0) continue;
      int indexName = 0;
      if (isItANumber(cutLine[0]))indexName = 1; // find indexName  

      if ( cutLine[0].charAt(0) == '0') readingEvt = int(cutLine[1]) ;
      if (evt == readingEvt) load = true; 
      if (evt != readingEvt) load = false ;

      //2. same evt : load data to structured Object
      if ( load && var2catch.hasValue(cutLine[indexName]) ) { 

        switch (cutLine[indexName].substring(0, 3)) {

        case "noi": // pafnoise case (i)
          if (cutLine[indexName].length() == 6 )  hm.get("osc").memorize(cutLine, indexName);//noise2    
          else if ( cutLine[indexName].startsWith("noisetutti")) {
            for (int j=1; j<=5; j++) { // there are only 5 noise vars
              cutLine[indexName] = "noise"+str(j);
              hm.get("osc").memorize(cutLine, indexName);
            }
          }
          break;

          case ("sto"): // for the synth vars which affect both sampler & osc
          String destination = cutLine[indexName].substring(1, 4);   
          cutLine[indexName] = "t"+destination;
          hm.get("sampler").memorize(cutLine, indexName);
          cutLine[indexName] = "o"+destination;
          hm.get("osc").memorize(cutLine, indexName);
          break; 

        default :
          TableRow row = routVars.matchRow(cutLine[indexName], "var");
          String parent = row.getString("mod"); // deduce parent mod from the Table
          hm.get(parent).memorize(cutLine, indexName);
          break;
        }
      }

      // it its a new evt : write data
      if (! load) { 
        TableRow newRow = table.addRow();  
        newRow.setString("evt", section+"."+evt);

        for (String k : hm.keySet()) hm.get(k).updateAndDeduce();
        hm.get("osc").updatePAf2noise();
        for (String k : hm.keySet()) hm.get(k).write();
        println('\n');
        println(evt);
        printRouting();

        evt = int(cutLine[1]);
      }
    }
  }
  table.addColumn("spat");
  saveTable(table, "modsConnections.tsv");
  exit();
}



////////////////////////// FUNCTION
boolean isItANumber( String testme) { 
  char [] number = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}; 
  for ( int i = 0; i  < number.length; i++ ) {
    if (testme.charAt(0) == number[i])   return true;
  }
  return false;
}

void init() {
  hm = new HashMap<String, Module>();
  table = new Table();
  routVars = loadTable("routingVars.txt", "header, tsv");
  var2catch = new StringList();
  table.addColumn("evt");

  for (int i=0; i<routVars.getRowCount(); i++) {
    table.addColumn(routVars.getString(i, "mod")); // add column for resulting table

    Module me = new Module( // instanciate object
      routVars.getString(i, "mod"), 
      routVars.getString(i, "type"), 
      routVars.getString(i, "var")
      );
    hm.put(me.name, me); // create instance of obj

    String [] temp = splitTokens(routVars.getString(i, "var"), ", ");
    var2catch.append(temp);
  }

  //Add the special vars synthVars & paf2noise
  var2catch.append(new String[]{"sto2", "sto4", "stof", "stoh", "stor"} );
  var2catch.append(new String[] {"noisetutti", "noisetutti4", "noisetutti6", "noisetutti8"} );
}

void printRouting() {
  //StringList toPrint = new StringList();
  for (String k : hm.keySet()) {
    Module me = hm.get(k); 
    if (me.outputs.size() > 0 )  println( me.outputs.join(" "));
  }
}
