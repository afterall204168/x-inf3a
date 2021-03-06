package config;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import sharing.SharingManager;



public class Settings {
	static private double version=0.4;
	static private String sharePath="shared";
	static private String configPath="configuration/conf";
	static private int maxTTL=5;
	static private long speed=5;
	

	static public double getVersion() {
		return version;
	}

	static public String getSharePath() {
		return sharePath;
	}
	
	static public int getMaxTTL() {
		return maxTTL;
	}
	
	static public long getSpeed() {
		return speed;
	}

	static public boolean load(){
		File fconf = new File(configPath);
		try {
			BufferedReader reader = new BufferedReader(new FileReader(fconf));
			String currentLine=reader.readLine();
			while(currentLine!=null){
				String[] tab  = currentLine.split(" ");
				handle(tab);
				currentLine=reader.readLine();
			}
			
		} catch (FileNotFoundException e) {
			return false;
		} catch (IOException e) {
			return false;
		}
		
		return true;	
	}
	
	static public boolean save(){
		File fconf = new File(configPath);		
		
		fconf.delete();
		
		
		try {
			PrintWriter write = new PrintWriter(new FileWriter(fconf));
			
			write.println("version: "+version);
			write.println("sharePath: "+sharePath);
			write.println("maxTTL: "+maxTTL);
			write.println("speed: "+speed);
		
			write.flush();
		} catch (FileNotFoundException e) {
			return false;
		} catch (IOException e) {
			return false;
		}
		
		return true;	
	}
	
	static private void handle(String[] value){//le premier élément de value est le nom du paramètre
		if(value[0].equals("version:"))version=Double.parseDouble(value[1]);
		else if(value[0].equals("sharePath:")) { sharePath = value[1]; SharingManager.setSharedDirPath(sharePath); }
		else if(value[0].equals("maxTTL:"))maxTTL = Integer.parseInt(value[1]);
		else if(value[0].equals("speed:"))speed = Long.parseLong(value[1]);
	}
	
}
