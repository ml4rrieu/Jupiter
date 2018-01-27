/**
goal : get the pre state of modules, to know if Modules are able to make sound or not.
this code load all qlist files.
last evt of section are not read, but we dont care since (hopefully) they are empty
ML 2016
 */

import java.util.Map;
HashMap<String, Module> hm;
Table table, modsVars ; 
StringList var2catch;
int section, evt, readingEvt;
boolean load;
String path;


void setup() {

  init();

  //0.load section score
  for (int section =1; section < 14; section ++) { // 13 section 
    if (section < 10 ) path = "../../../../myJupiter/rebuildPatch/score/section0"+section+"-qlist.txt" ;
    if (section >=10) path =    "../../../../myJupiter/rebuildPatch/score/section"+section+"-qlist.txt" ;
    String [] score  = loadStrings(path);

    //1. iterate throw score
    evt = 0;
    for (int i=0; i< score.length; i++) {
      String[] cutLine = splitTokens(score[i], " ,;");

      //2.go through undesired lines
      if ( cutLine[0].equals("comment")) continue;
      int tempRemoveNumber = 0;
      for (int j=0; j<cutLine.length; j++ ) if (!isItANumber(cutLine[j])) tempRemoveNumber+=1 ;
      if (tempRemoveNumber == 0) continue;
      
      // find indexName & indexValue
      int indexName = 0;
      if (isItANumber(cutLine[0]))indexName = 1;   
      int indexValue = indexName+ 1;
      if (cutLine.length - (indexName+1) > indexName+2) indexValue = indexName+2; //hamp1 0, 127 2000


      //3.is it  new event ? 
      if (cutLine[0].charAt(0) == '0' )readingEvt = int(cutLine[1]);
      if (evt == readingEvt) load = true; 
      if (evt != readingEvt) load = false ; 

      //3.0 load data into structured Objects
      if ( load && var2catch.hasValue(cutLine[indexName])) {
        // 3.1 paf case : env
        if ( cutLine[indexName].substring(0, 3).equals("env")) {
          String var = "amp"+cutLine[indexName].substring(3, 4);
          hm.get("paf").memorize(var, cutLine[indexName+2]);
          hm.get("paf").memorize(var, cutLine[indexName+4]);
          if (cutLine.length > 8) println("there is a big env "+join(cutLine, " "));
        }

        //3.2 paf case : amptutti 
        else if (cutLine[indexName].length() == 9) {
          for (int j = 1; j<= int(cutLine[indexName].substring(8, 9)); j++) {
            hm.get("paf").memorize("amp"+str(j), cutLine[indexValue]);
          }
        }

        //3.3 paf case : pufamp (apregator) 
        else if (cutLine[indexName].equals("pufamp")) {
          for (int j=1; j < cutLine.length - 1; j++) { // pufamp -1 127 127 138 138
            hm.get("paf").memorize("amp"+str(j), cutLine[j+1]);
          }
        }

        //3.4 harm case : trans 
        else if (cutLine[indexName].startsWith("tran")) {
          String nb = cutLine[indexName].substring(5, 6); //trans1 to 4
          hm.get("harm").memorize("hamp"+nb, "127");
        } 

        //3.5 else ... if it is  natif var of mods
        else {
          // println( cutLine[indexName]);
          TableRow row = modsVars.matchRow(cutLine[indexName], "var");
          String parent = row.getString("mod"); // deduce parent mod from the Table
          hm.get(parent).memorize(cutLine[indexName], cutLine[indexValue]);
        }
      }

      //3.1 or write data
      if (!load ) {
        TableRow newRow = table.addRow(); 
        newRow.setString("evt", section+"."+evt);
        newRow.setString("flute", "1");
        newRow.setString("noise", "1");
        newRow.setString("spat", "1");

        //println('\n');
        println(newRow.getString(0));
        //for (String k : hm.keySet()) hm.get(k).printVars();
        for (String k : hm.keySet()) hm.get(k).deduceState();
        for (String k : hm.keySet()) hm.get(k).writeState(); 
        for (String k : hm.keySet()) hm.get(k).buffer.clear();
        evt = int(cutLine[1]);
      }
    }
  }

  //add state of synth mods (extracted manually) to table
  writeStateModForThisInterval("additive", new String[] {"3.65 to 3.93"});
  writeStateModForThisInterval("chapo", new String[] {"6.1 to 6.32", "12.1 to 12.30"});
  String[] samplerState = {"2.77 to 3.8", "3.33 to 3.63", "3.65 to 3.80", "3.83 to 3.128",
    "5.1 to 5.5", "5.7 to 5.10", "5.12 to 5.24", "8.2", "8.4", "8.6", "8.8 to 8.22", "8.24 to 8.27",
    "9.2 to 9.11", "9.13 to 9.14", "10.2 to 10.12", "10.14 to 10.15"};
  writeStateModForThisInterval("sampler", samplerState);

  saveTable(table, "preStatesOfMods.tsv");
  exit();
}


////////////////////////myFunction
boolean isItANumber( String testme) { 
  char [] number = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}; 
  for ( int i = 0; i  < number.length; i++ ) {
    if (testme.charAt(0) == number[i])   return true;
  }
  return false;
}


//////////////////////// my void

void writeStateModForThisInterval(String mod, String[] interval) {

  for (int j=0; j< interval.length; j++) {
    String[] cut =  split(interval[j], "to");
    if (cut.length ==1) table.setInt( table.findRowIndex(trim(cut[0]), "evt"), mod, 1) ;
    else {
      int indexStart = table.findRowIndex ( trim(cut[0]), "evt");
      int indexStop = table.findRowIndex ( trim(cut[1]), "evt");
      for (int i = indexStart; i < indexStop+1; i++)table.setInt(i, mod, 1);
    }
  }
}


void init() {
  hm = new HashMap<String, Module>();
  table = new Table();
  var2catch = new StringList();
  modsVars = loadTable("modsVars.txt", "header,tsv");
  table.setColumnTitles(new String[]{"evt", "flute", "sampler", "additive", "chapo", "paf", "reverb", "harm", "freqShift", "noise", "spat"});

  for (int i=0; i< modsVars.getRowCount(); i++) {
    Module me= new Module(
      modsVars.getString(i, "mod"), 
      modsVars.getString(i, "type"), 
      modsVars.getString(i, "var")
      ); // create objetcs for each mods
    hm.put(me.name, me);

    String [] cutVars = modsVars.getString(i, "var").split(", ");
    cutVars = trim(cutVars);
    for (int j=0; j< cutVars.length; j++) {
      var2catch.append(trim(cutVars[j])); //put vars we are searching in StringList
    }
  }
  //add special vars for paf & harm
  var2catch.append(new String[]{"env1", "env2", "env3", "env4", "env5", "env6", "env7", "env8"});
  var2catch.append(new String[]{"amptutti4", "amptutti5", "amptutti6", "amptutti8", "pufamp"});
  var2catch.append(new String[]{"trans1", "trans2", "trans3", "trans4"});
}
