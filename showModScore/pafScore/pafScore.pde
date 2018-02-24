/*
goal : extract the state of paf channel's, so that we dont have to read independently 
all the variables. 
this code load pafQlist.txt and midi2note.tsv, and ouput the result in the consol
ML 2016
*/

import java.util.Map;
Paf paf;
Table noteMidi; 
StringList oldData, delay, buffer; 
String section, var; 
int evt, readingEvt, nb;

void setup() {
  paf = new Paf();
  noteMidi= loadTable("midi2note.tsv", "header");
  String[] score = loadStrings("../pafQlist.txt");
  oldData = new StringList();
  delay = new StringList();
  buffer = new StringList();
  evt = 0; 

  for (int i=0; i<score.length; i++) { //for (int i=1526; i<1590; i++) {  
    boolean newEvt = false, newDelay = false;
    score[i] = trim(score[i]);
    if (score[i].isEmpty()) continue;
    String[] line = splitTokens(score[i], " ,");

    // PART A. DEAL WITH EVENT AND DELAY
    if (line[0].equals("SECTION")) {
      section = line[1];
      continue;
    }

    if (line[0].equals("evt")) {
      readingEvt = int(line[1]);
      newEvt = true;
    }

    if (isItANumber(line[0])) { 
      newDelay = true; 
      delay.append(line[0]);
    }

    // if it is a new evt : send data to print
    if (newEvt) {
      StringList output =  new StringList();
      if ( buffer.size()>0 )  output = buffer.copy(); 
      if (changeOccured()) {
        if (buffer.size() == 0) output.append(section+"."+evt);
        if (delay.size()>0) output.append(str(sumDelay()));
        output.append( outputChanged());
      }

      //make sum of successive lines of delay
      IntList index2remove = new IntList();
      int j = 0; 
      while (j <= output.size()-2 ) {
        int sumDel = 0;
        String [] cut1 = splitTokens(output.get(j), " .");
        String [] cut2 = splitTokens(output.get(j+1), " .");
        if (cut1.length == 1 && cut2.length == 1) { 
          sumDel = int( output.get(j) ) + int( output.get(j+1) ); 
          index2remove.append(j);
          output.set(j+1, str(sumDel) );
        }
        j+=1;
      }

      // make structureOutput & print it
      StringList structuredOut = new StringList();
      for (int k = 0; k< output.size(); k++) {
        if ( index2remove.hasValue(k)) continue; 
        String [] cutEvt = splitTokens(output.get(k), ".");
        String [] cutDel = splitTokens(output.get(k), " .");
        if (k == output.size()-1 && cutDel.length ==1 ) break; // if last line is a del break
        if ( cutEvt.length==2 ) structuredOut.append( output.get(k) );
        else structuredOut.append("\t"+ output.get(k) );
      }

      if (structuredOut.size()>0) structuredOut.insert(0, "\t"); // add empty line before printing
      for (String v : structuredOut) println(v);
      buffer.clear();
      delay.clear();
      evt = readingEvt;
      continue;
    }

    // if its not a newEvt but delay occured and there is a change in paf configuration
    if (newDelay && changeOccured()) {
      if (delay.size()>0) delay.remove(delay.size()-1);
      if (buffer.size()== 0) buffer.append(section+"."+readingEvt);
      for (String v : delay) buffer.append(v);
      delay.clear();
      buffer.append(outputChanged());
      buffer.append(line[0]);
      continue;
    }
    if (newDelay) continue; 

    // PART B SEND VALUE TO PAF SCTRUCTUED OBJECT
    // 1. if it is puf vars for the apreg
    if (line[0].startsWith("puf") || line[0].startsWith("vib")) {
      var = line[0].substring(3, line[0].length());
      paf.pufDistrib(var, line);
      continue;
    } 

    // 2. for tuttis var 
    if (line[0].endsWith("tutti")) {
      var = line[0].substring(0, line[0].lastIndexOf("u")-1);
      paf.updateTutti(var, line, 8);
      continue;
    } 

    // 3. for amputti
    if (line[0].startsWith("amptutti")) {
      var = line[0].substring(0, line[0].lastIndexOf("u")-1);
      int nbOfChannels = int( line[0].substring( line[0].length()-1, line[0].length() ));
      paf.updateTutti(var, line, nbOfChannels);
      continue;
    } 

    // 4 . for single vars eg env3 
    nb = int(line[0].substring(line[0].length()-1));
    var = line[0].substring(0, line[0].length()-1);
    paf.updateSingle(nb, var, line);
  }

  exit();
}


boolean changeOccured() {
  oldData = new StringList();
  oldData = paf.representation.copy();
  paf.doRepresentation();
  if (compare2StringLists(oldData, paf.representation)) return false;
  else return true;
}

StringList outputChanged() {

  //put the diff between last event in temp (but if its "mute" value store them)
  StringList temp = new StringList();
  StringList getMute = new StringList();
  for (int i=0; i<oldData.size(); i++) {
    if (! oldData.get(i).equals(paf.representation.get(i))) {
      if (paf.representation.get(i).endsWith("mute")) getMute.append( paf.representation.get(i).substring(0, 1)); 
      else temp.append(paf.representation.get(i));
    }
  }

  if (getMute.size()>0)temp.insert(0, "mute "+ getMute.join(" ")); //insert mute value
  return temp;
}

int sumDelay() {
  int temp=0 ; 
  for ( String v : delay) temp+= int(v);
  return temp;
}

boolean isItANumber( String testme) { 
  char [] number = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}; 
  for ( int i = 0; i  < number.length; i++ ) {
    if (testme.charAt(0) == number[i])   return true;
  }
  return false;
}

boolean compare2StringLists(StringList a, StringList b) {
  for (String v : a)if (!b.hasValue(v)) return false;
  return true;
}