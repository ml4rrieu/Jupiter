/**
goal : have a clean score per Module with only the occurence of the var we are searching for.
cf. at the end for all the var per module
this patch need to load qlist files
ML 2016
 */

PrintWriter output; 
StringList undesirableVar, var2catch, buffer, delayTime;
Table table; 
int evt, readingEvt;
boolean load, findVar; 

void setup() {
  var2catch = new StringList() ; 
  buffer = new StringList();
  delayTime = new StringList();
  table = new Table();
  findVar = false; 
  table.addColumn("evt");

  //name output file 
  String name4file = "freqShift";
  output = createWriter(name4file+"Qlist.txt");

  //catchPaf();
  //var2catch.append(new String[]{"revfb", "rgate", "rout"});
  //var2catch.append(new String[]{"hfre1", "hfre2", "hfre3", "hfre4", "trans1", "trans2", "trans3", "trans4", "hwind", "hdel1", "hdel2", "hdel3", "hdel4", "hamp1", "hamp2", "hamp3", "hamp4","hto2"});  
  var2catch.append(new String[]{"fpos", "fneg", "fsfre", "fto2"});
  //var2catch.append(new String[]{"fnois", "nto2"});

  for (String v : var2catch.values()) table.addColumn(v);

  //load score for each section
  for (int sectNb = 1; sectNb < 14; sectNb++) { 
    String path="";
    if (sectNb < 10 ) path = "../score/section0"+str(sectNb) ; // qlists path
    if (sectNb >=10) path =  "../score/section"+str(sectNb) ;
    String score[] = loadStrings(path+"-qlist.txt");
    output.println('\n'+"SECTION "+sectNb+'\n');

    //iterate throw score
    evt = 0;
    for (int i = 0; i < score.length; i++) {
      String[] line = splitTokens(score[i], " ,;");

      //2. skip undesired lines & find indexName
      if ( line[0].equals("comment")) continue;
      int tempRemoveNumber = 0;
      for (int j=0; j<line.length; j++ ) if (!isItANumber(line[j])) tempRemoveNumber+=1 ;
      if (tempRemoveNumber == 0) continue;
      int indexName = 0;
      if (isItANumber(line[0])) {
        if (!line[0].equals("0")) buffer.append(line[0]); // add delay time in the writer
        indexName = 1; // find indexName
      } else if (!isItANumber(line[0])) indexName = 0;
      int indexValue = indexName+ 1;
      if (line.length - (indexName+1) > indexName+2) indexValue = indexName+2; //hamp1 0, 127 2000 useless for synth var

        //3.is it  new event ?
      if (line[0].charAt(0) == '0' ) readingEvt = int( line[1] );
      if (evt == readingEvt) load = true; 
      if (evt != readingEvt) load = false ; 

      if (load && var2catch.hasValue(line[indexName])) {
        if (line[indexName].equals("fsfre")) buffer.append("fsfre "+mtof(int(line[indexValue]))); // print fsfre as freq value
        else buffer.append(line[indexName]+" "+line[indexValue]); // if we are dealing with amplitude variable

        /* StringList glueLine = new StringList();
         for (int j=indexName+1; j< line.length; j++) glueLine.append(line[j]);
         buffer.append(line[indexName]+" "+glueLine.join(",") ); */
        findVar = true;
      }

      // if it is a new evt & the vars we are searching are present
      if (!load && findVar) {
        output.println('\n'+"evt "+evt);

        // find the index in the buffer of the last value (so that we avoid delay times after the var occured)
        int lastIndexOfValue = 0;
        for (int j=buffer.size()-1; j>=0; j--) {
          String[] cut = split(buffer.get(j), " "); 
          if (!isItANumber(cut[0])) {
            lastIndexOfValue = j;
            break;
          }
        }

        //print the buffer until the last var occurence
        for (int j=0; j <= lastIndexOfValue; j++) {
          output.println('\t'+ buffer.get(j) ); // for the text

          String[]cut = split( buffer.get(j), " ");
          // if it is not a delay time then write data to table
          if (cut.length>1) {
            TableRow row = table.findRow(str(sectNb)+"."+str(evt), "evt"); 
            if (row != null) row.setString(cut[0], cut[1]);
            else {
              TableRow newRow = table.addRow();
              newRow.setString(0, str(sectNb)+"."+str(evt));
              newRow.setString(cut[0], cut[1]);
            }
          }
        }

        buffer.clear();
        findVar = false;
        evt = int(line[1]);
      }

      // if only delay times were added
      if ( !load && !findVar) {
        //remove delay times in buffer
        for (String v : buffer) if (isItANumber(v))buffer.removeValue(v);       
        evt = int(line[1]);
      }
    }
  }


  saveTable(table, name4file+"Qlist.tsv");
  output.flush();  // Writbuffer.See the remaining data to the file
  output.close();  // Finishes the file
  exit();
}

boolean isItANumber( String testme) { 
  char [] number = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}; 
  for ( int i = 0; i  < number.length; i++ ) {
    if (testme.charAt(0) == number[i])   return true;
  }
  return false;
}

int mtof(float in) {
  if (in > 1499) in = 1499; 
  if ( in< - 1500) in = -1500;
  //(8.17579891564 * exp(0.0577622650 * MIDI_note)) = frequency

  return round( 8.17579891564 * exp(0.0577622650 * in));
}



/*sampler var
 "addsamp, sec2-evt77, sec2-evt78, evt68, evt76, evt79,"+
 "evt80, evt83, evt87, evt88, evt89, evt90, evt91, sec3-evt33, evt93,"+
 "evt94, evt95, evt96, evt97, evt98, evt99, evt100, evt123, inter1a-start,"+
 "inter1c-start, inter1d-start, inter2a-start, inter2b-start, inter2c-start,"+
 "inter2d-start, ost1-start, ost2-start, ost3-start, ost4-start, ost4b-start,"+
 "ost5-start, ost6-start, ost7-start, ost8-start"; */


//paf VAR
void catchPaf() {
  //amp
  var2catch.append(new String[]{"amp1", "amp2", "amp3", "amp4", "amp5", "amp6", "amp7", "amp8", "pufamp"});
  var2catch.append(new String[]{"amptutti4", "amptutti5", "amptutti6", "amptutti8"});  
  //env
  var2catch.append(new String[]{"env1", "env2", "env3", "env4", "env5", "env6", "env7", "env8"}); // specific to amp : do ADSR
  //pitch
  var2catch.append(new String[]{"pitch1", "pitch2", "pitch3", "pitch4", "pitch5", "pitch6", "pitch7", "pitch8", "pufpitch"});
  //cf  
  var2catch.append(new String[]{"cf1", "cf2", "cf3", "cf4", "cf5", "cf6", "cf7", "pufcf"});
  //bw
  var2catch.append(new String[]{"bw1", "bw2", "bw3", "bw4", "bw5", "bw6", "bw7", "pufbw"});
  //virabto freq & depth
  var2catch.append(new String[]{"vfreq1", "vfreq2", "vfreq3", "vfreq4", "vfreq5", "vfreq6", "vfreq7", "vfreqtutti", "vfreqtutti8"}); 
  var2catch.append(new String[]{"vamp1", "vamp2", "vamp3", "vamp4", "vamp5", "vamp6", "vamp7", "vamptutti", "vamptutti8"});
  var2catch.append(new String[]{"pufvfreq", "pufvamp"});  
  //FS
  var2catch.append(new String[]{"shift1", "shift2", "shift3", "shift4", "shift5", "shift6", "shift7", "shift8", "shifttutti"});
}

/*// undesirable vars
 undesirableVar.append(new String[] {"inatten", "ph-wind", "phto4", "fiddle", "pt-default-bounce", "which-synth", "pt-bounce"});
 */