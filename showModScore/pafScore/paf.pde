/*
the Paf class used in pafSCore.pde
ML 2016
*/

class Paf {
  ArrayList<Channel> channels = new ArrayList<Channel>();
  StringList representation = new StringList();

  Paf() {
    // create channels from 1 to 8
    for (int i=0; i<= 8; i++) channels.add(new Channel(i));
  }

  void updateSingle(int i, String var, String[] line) {
    if (var.equals("env")) { //env1 -1,150,8,140,200,-2
      channels.get(i).hm.get("amp").value[0]=int(line[2]);
      channels.get(i).hm.get("amp").value[1]=int(line[3]);
      channels.get(i).hm.get("amp").value[0]=int(line[4]);
      channels.get(i).hm.get("amp").value[1]=int(line[5]);
    } else channels.get(i).setLineVar(var, line);
  }

  void updateTutti(String var, String[] line, int stop) { //amptutti 0,5
    for (int i=1; i<= stop; i++) channels.get(i).setLineVar(var, line);
  }

  void pufDistrib(String var, String[] line) { // puffq -1,8600,6800,9100
    for (int i=1; i<line.length-1; i++) channels.get(i).hm.get(var).value[0] = int(line[i+1]);
  }

  void doRepresentation() {
    representation.clear();
    for (int i=1; i<9; i++) channels.get(i).writeDataChannel();
  }

  class Channel {
    HashMap<String, Var> hm = new HashMap<String, Var>();
    StringList varPerChannel = new StringList();
    int nb; 

    Channel(int n) {
      nb = n;
      varPerChannel.append(new String[]{"amp", "pitch", "cf", "bw", "shift", "vfreq", "vamp", });

      for (String v : varPerChannel) {
        Var me = new Var();
        hm.put(v, me);
      }
    }

    void setLineVar(String varName, String[] line) {
      hm.get(varName).value[0]=int(line[1]);

      if (line.length == 3) hm.get(varName).value[1]=int(line[2]);    //cf3 40 500      
      if (line.length == 4) { //amptutti 0 120 3000
        hm.get(varName).value[0]= int(line[2]);
        hm.get(varName).value[1]=int(line[3]);
      }
    }

    void writeDataChannel() {
      if (hm.get("amp").value[0] ==0 )representation.append(nb+" mute");
      else {

        StringList glueVar = new StringList();
        for (String v : varPerChannel) {
          if (v.equals("amp")) continue;
          switch(v) {
            case ("pitch"):
            int noteNb = hm.get("pitch").value[0]/100;
            TableRow row = noteMidi.findRow(str(noteNb), 0);
            if (row != null) glueVar.append(row.getString("midiNote")+row.getString("octave"));
            else glueVar.append("pitch "+ str(noteNb));
            break;

            case ("cf"):
            int diffPitchCf = hm.get("cf").value[0] - hm.get("pitch").value[0]/100;
            String temp ;
            if ( diffPitchCf >0) temp = "+"+ diffPitchCf;
            else temp = "- "+ diffPitchCf;
            glueVar.append("cf "+ temp);
            break;
          default:
            if (hm.get(v).value[0]>0) glueVar.append(v+" "+hm.get(v).value[0]);
            break;
          }
        }
        representation.append(nb+" "+glueVar.join(" "));
      }
    }
  }
}


class Var {
  int [] value;
  Var() {
    value = new int[2];
  }
}