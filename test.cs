using System;
using System.Threading;
using System.DirectoryServices;

namespace changeC
{
    class Program
    {


		private static void EnableAccount(string accountDn, string dcIP)
		{
		
            DirectoryEntry uEntry = new DirectoryEntry("LDAP://" + dcIP + "/" + accountDn);
			
			int val = (int)uEntry.Properties["userAccountControl"].Value;
			Console.WriteLine("Value of the userAccountControl property:");
			Console.WriteLine(val);
			uEntry.Properties["userAccountControl"].Value = val & ~0x0002;
			uEntry.CommitChanges();
			Console.WriteLine("After the change - Value of the userAccountControl property:");
			val = (int)uEntry.Properties["userAccountControl"].Value;
			Console.WriteLine(val);
			uEntry.Close();
		}


		private static void DisableAccount(string accountDn, string dcIP)
		{
	
            DirectoryEntry uEntry = new DirectoryEntry("LDAP://" + dcIP + "/" + accountDn);
			
			int val = (int)uEntry.Properties["userAccountControl"].Value;
			Console.WriteLine("Value of the userAccountControl property:");
			Console.WriteLine(val);
			uEntry.Properties["userAccountControl"].Value = val | 0x0002;
			uEntry.CommitChanges();
			Console.WriteLine("After the change - Value of the userAccountControl property:");
			val = (int)uEntry.Properties["userAccountControl"].Value;
			Console.WriteLine(val);
			uEntry.Close();
		}

		public static void SleepMinutes(int minutes)
        {
            int mSec = minutes * 60 * 1000;
            Thread.Sleep(mSec);
        }
        
        public static void ResetPassword(string accountDn, string dcIP, string password)
        {
			accountDn = "CN=marcin,CN=Users,DC=RED,DC=LAB";
            DirectoryEntry uEntry = new DirectoryEntry("LDAP://" + dcIP + "/" + accountDn);
            uEntry.Invoke("SetPassword", new object[] { password });
            uEntry.Close();
        }

        static void Main(string[] args)
        {
			string dcIP = "....";
			string accountDn = "...";
            // string newPass = "ASDF@87234ab";
			DisableAccount(accountDn, dcIP);
            // ResetPassword(accountDn, dcIP, newPass);
			SleepMinutes(2);
        }
    }
}



