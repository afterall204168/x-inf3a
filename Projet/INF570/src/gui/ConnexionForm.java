package gui;
import java.awt.BorderLayout;
import java.awt.event.ActionEvent;

import javax.swing.AbstractAction;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.WindowConstants;

import connexion.ConnexionManager;

/**
* This code was edited or generated using CloudGarden's Jigloo
* SWT/Swing GUI Builder, which is free for non-commercial
* use. If Jigloo is being used commercially (ie, by a corporation,
* company or business for any purpose whatever) then you
* should purchase a license for each developer using Jigloo.
* Please visit www.cloudgarden.com for details.
* Use of Jigloo implies acceptance of these licensing terms.
* A COMMERCIAL LICENSE HAS NOT BEEN PURCHASED FOR
* THIS MACHINE, SO JIGLOO OR THIS CODE CANNOT BE USED
* LEGALLY FOR ANY CORPORATE OR COMMERCIAL PURPOSE.
*/
public class ConnexionForm extends javax.swing.JDialog {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private JButton ok;
	private JPanel jPanel1;
	private JTextField port;
	private AbstractAction abstractAction1;
	private AbstractAction cancel;
	private JLabel Title;
	private JPanel jPanel3;
	private JTextField ip;
	private JPanel jPanel2;
	private JButton Annuler;
	private	String ipadress;
	private int portutilise;



	/**
	* Auto-generated main method to display this JDialog
	*/
	
	public ConnexionForm() {
		initGUI();
	}
	
	private void initGUI() {
		try {
			{
				this.setTitle("Nouvelle Connexion");
				getContentPane().setBackground(new java.awt.Color(224,224,224));
				this.setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
				this.setLocationRelativeTo(null);
				{
					jPanel1 = new JPanel();
					getContentPane().add(jPanel1, BorderLayout.CENTER);
					jPanel1.setPreferredSize(new java.awt.Dimension(269, 163));
					jPanel1.setLayout(null);
					jPanel1.setBackground(new java.awt.Color(224,224,224));
					{
						jPanel3 = new JPanel();
						jPanel1.add(jPanel3, "North");
						BorderLayout jPanel3Layout = new BorderLayout();
						jPanel3.setLayout(jPanel3Layout);
						jPanel3.setBounds(36, 41, 204, 31);
						jPanel3.setBackground(new java.awt.Color(224,224,224));
						{
							port = new JTextField();
							jPanel3.add(port, BorderLayout.EAST);
							port.setText("7777");
							port.setPreferredSize(new java.awt.Dimension(47, 29));
						}
						{
							ip = new JTextField();
							jPanel3.add(ip, BorderLayout.WEST);
							ip.setText("localhost");
							ip.setPreferredSize(new java.awt.Dimension(137, 29));
						}
					}
					{
						jPanel2 = new JPanel();
						BorderLayout jPanel2Layout = new BorderLayout();
						jPanel2.setLayout(jPanel2Layout);
						jPanel1.add(jPanel2, "South");
						jPanel2.setBounds(70, 83, 170, 26);
						jPanel2.setBackground(new java.awt.Color(224,224,224));
						{
							Annuler = new JButton();
							jPanel2.add(Annuler, BorderLayout.EAST);
							Annuler.setText("Annuler");
							Annuler.setPreferredSize(new java.awt.Dimension(81, 23));
							Annuler.setAction(getCancel());
						}
						{
							ok = new JButton();
							BorderLayout okLayout = new BorderLayout();
							ok.setLayout(okLayout);
							jPanel2.add(ok, BorderLayout.WEST);
							ok.setText("Ok");
							ok.setPreferredSize(new java.awt.Dimension(70, 23));
							ok.setAction(getAbstractAction1());
						}
					}
					{
						Title = new JLabel();
						jPanel1.add(Title);
						Title.setText("Nouvelle connexion :");
						Title.setBounds(26, 0, 233, 35);
						Title.setFont(new java.awt.Font("Tahoma",1,12));
						Title.setForeground(new java.awt.Color(0,0,128));
					}
				}
			}
			this.setSize(272, 164);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	private AbstractAction getAbstractAction1() {
		if(abstractAction1 == null) {
			abstractAction1 = new AbstractAction("Ok", null) {
				/**
				 * 
				 */
				private static final long serialVersionUID = 1L;

				public void actionPerformed(ActionEvent evt) {
					ipadress = ip.getText();
					portutilise = Integer.parseInt(port.getText());
					ConnexionManager.connect(ipadress, portutilise);
					dispose();
				}
			};
		}
		return abstractAction1;
	}
	
	private AbstractAction getCancel() {
		if(cancel == null) {
			cancel = new AbstractAction("Annuler", null) {
				/**
				 * 
				 */
				private static final long serialVersionUID = 1L;

				public void actionPerformed(ActionEvent evt) {
					dispose();
				}
			};
		}
		return cancel;
	}

}
