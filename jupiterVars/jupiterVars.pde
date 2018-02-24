/*
this code  catch all the variables present in the qlist files and add desctiptions.
This code load all qlist files and output a table
ML 2016
*/

Table table;
String varName ;
StringList args ; 
int sectNb, evtNb ; 
String path;

void setup() {

  table = loadTable( "../jupiterVarsPre.csv", "header, csv"); //a base table where I added some textual info for each vars

  table.addColumn("occurence");
  table.addColumn("section", Table.STRING);
  table.addColumn("dataType", Table.STRING);
  table.addColumn("min");
  table.addColumn("max");
  table.addColumn("argNb");
  table.addColumn("text", Table.STRING);


  for ( sectNb = 1; sectNb < 14; sectNb ++) {
    if (sectNb < 10 ) path = "../score/section0"+str(sectNb) ; // qlist path
    if (sectNb >=10) path =    "../score/section"+str(sectNb) ;

    String getScore[] = loadStrings(path+"-qlist.txt");
    println("treating section nb " + sectNb);
    evtNb = 0;

    for (int i = 0; i<getScore.length; i++) {
      String[] cutLines = splitTokens(getScore[i], " ;");

      if (cutLines[0].equals("comment")) continue; // sauter les lignes commentaires
      if (getScore[i].charAt(0) == '0' ) continue;  // sauter les evt

      // sauter les lignes faites de nombres
      int tempRemoveNumber = 0;
      for (int j = 0; j < cutLines.length; j++) if (!isItANumber(cutLines[j]) ) tempRemoveNumber+=1 ;
      if (tempRemoveNumber == 0) continue;

      addOrActualiseThis(cutLines); // actualise var
    }
  }

  for (TableRow row : table.findRows("1,2,3,4,5,6,7,8,9,10,11,12,13", "section")) row.setString("section", "all");

  table.sort("name"); 
  saveTable(table, "jupiterVars.csv"); 
  exit();
}

//////////////////// my functions
void addOrActualiseThis(String[] line) {
  args = new StringList(); 

  // identifier le nom de la var et ajouter les arguments
  if (!isItANumber(line[0])) {
    varName = line[0]; 
    for (int i = 1; i < line.length; i++ ) args.append(line[i]);
  }

  if (isItANumber(line[0])) {
    varName = line[1]; 
    for (int i = 2; i < line.length; i++ ) args.append(line[i]);
  }
  if (varName.equals("vfreqtutti8") ) println('\t', varName); /// why ? c'est inutile ... 

  TableRow result = table.findRow(varName, "name"); 
  if (result == null ) { // si la var n'est pas présente
    TableRow newRow = table.addRow(); 
    newRow.setString("name", varName); 
    actualiseValues(newRow, args);
  }

  // si la var est deja présente
  if (result != null ) actualiseValues(result, args);
}


void actualiseValues(TableRow thisRow, StringList args) {
  String[] argArray = args.array(); 
  String glueArg = join(argArray, " "); 

  //traiter le champs dataType
  if (thisRow.getString("dataType") == null ) { 
    String dataType; 
    if (!isItANumber(args.get(0))) dataType = "text"; 
    else if (args.size() <= 2 ) dataType = "number"; 
    else if (args.size() == 3 && args.get(0).contains(",")) dataType = "number";     
    else dataType = "list"; 
    thisRow.setString("dataType", dataType);
  }

  //traiter chps occurence
  int incrEvt = thisRow.getInt("occurence") + 1; 
  thisRow.setInt("occurence", incrEvt); 


  //traiter le chps section
  if (thisRow.getString("section") == null ) thisRow.setString("section", str(sectNb) ); 
  else {
    String [] tempSection = split(thisRow.getString("section"), ","); 
    if (int(tempSection[tempSection.length-1]) != sectNb ) { 
      thisRow.setString("section", thisRow.getString("section") +","+str(sectNb) );
    }
  }

  /////traiter les chps min, max, list, text
  switch (thisRow.getString("dataType")) {
  case "number" : // si c'est un nombre 
    updateMinMax(thisRow, glueArg ); 
    break; 

  case "list" : //si c'est une liste
    if (argArray.length > thisRow.getInt("argNb")) { // on actualise le chps text uniquement si le nb d'arg est plus gd que celui enregistré
      thisRow.setInt("argNb", argArray.length); 
      thisRow.setString("text", join(argArray, " "));
    }
    break; 

  case "text" : // si c'est du texte
    String temp4text = thisRow.getString("text"); 
    if (temp4text == null) thisRow.setString("text", glueArg); 
    else { // si ya deja du texte on l'ajoute a la suite apres l'esperluette      
      if ( !temp4text.equals(glueArg)) {
        glueArg = temp4text +" & "+ glueArg; 
        thisRow.setString("text", glueArg);
      }
    }
    break;
  }
}

void updateMinMax (TableRow thisRow, String argInline) {
  //remove comma
  String[] in =  splitTokens(argInline, " ,");
  for (int i=0; i< in.length; i++) trim(in[i]);

  //get min max recorded in table
  String min =  str(thisRow.getFloat("min")); 
  String max = str(thisRow.getFloat("max"));

  // deduce which arg have to be considered 
  int indexValue =0 ;
  if ( in.length <=2) indexValue = 0;
  if ( in.length == 3) indexValue = 1; // nto2 0, 90 2000

  if (!isItANumber(min)) thisRow.setInt("min", int(in[indexValue]));
  else if ( float(in[indexValue]) < int(min)) thisRow.setInt("min", int(in[indexValue]));

  if (!isItANumber(max) && float(in[indexValue]) > float(min))thisRow.setInt("max", int(in[indexValue]));
  if (isItANumber(max) && float(in[indexValue]) > float(max)) thisRow.setInt("max", int(in[indexValue]));
}

// if the first char is number so the string is number
boolean isItANumber( String testme) {
  char [] number = {'-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}; 
  for ( int i = 0; i  < number.length; i++ ) {
    if (testme.charAt(0) == number[i])   return true;
  }
  return false;
}