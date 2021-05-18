```csharp
using System;
using System.IO;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Reflection;

namespace SQL
{
    class Program
    {

        static List<String> ExecuteQuery(SqlConnection con, String query)
        {
            List<String> resultList = new List<String>();
            SqlCommand command = new SqlCommand(query, con);
            SqlDataReader reader = command.ExecuteReader();

            while (reader.Read() == true)
                resultList.Add(reader[0].ToString());

            reader.Close();

            return resultList;

        }

        public static SqlConnection ConnectSQLServerIntegrated(String conString)
        {
            SqlConnection con = new SqlConnection(conString);

            try
            {
                con.Open();
                Console.WriteLine("[+] Auth success!");
            }
            catch
            {
                Console.WriteLine("[-] Auth failed");
                Environment.Exit(0);
            }

            return con;
        }

        static public bool isRoleMember(SqlConnection con, String sqlRole)
        {
            String query = String.Format("SELECT IS_SRVROLEMEMBER('{0}');", sqlRole);

            String result = ExecuteQuery(con, query)[0];

            Int32 role = Int32.Parse(result);
            if (role == 1)
                return true;
            else
                return false;
        }

		static public String ConsoleQueryResults(List<String> resultList)
        {
            String result = null;
            for (int i = 0; i < resultList.Count; i++)
                result += resultList[i] + "\n";
            return result;
        }

        static void Main(string[] args)
        {
            if (args.Length != 2)
            {
                string codeBase = Assembly.GetExecutingAssembly().CodeBase;
                string progName = Path.GetFileName(codeBase);

                Console.WriteLine("[-] Please supply arguments, e.g.:");
                Console.WriteLine(String.Format("{0} {1} {2}", progName, "DC_1..com", "master"));
                return;
            }

            String sqlServer = args[0];
            String database = args[1];
            String conString = String.Format("Server = {0}; Database = {1}; Integrated Security = True;",
                sqlServer, database);

            SqlConnection con = ConnectSQLServerIntegrated(conString);

            String query = "SELECT SYSTEM_USER;";
            Console.WriteLine("[+] Executed query: \n\n" + query + "\n");
            String result = ExecuteQuery(con, query)[0];
            Console.WriteLine("[+] Logged in as: " + result);

            query = "SELECT USER_NAME();"; // to which username you are mapped to
            Console.WriteLine("[+] Executed query: \n\n" + query + "\n");
            result = ExecuteQuery(con, query)[0];
            Console.WriteLine("[+] Mapped to the user: " + result);

            query = String.Format("SELECT IS_SRVROLEMEMBER('{0}');", "public");
            Console.WriteLine("[+] Executed query: \n\n" + query + "\n");

            if (isRoleMember(con, "public"))
                Console.WriteLine("[+] User is a member of public role");
            else
                Console.WriteLine("[-] User is NOT a member of public role");

            query = String.Format("SELECT IS_SRVROLEMEMBER('{0}');", "sysadmin");
            Console.WriteLine("[+] Executed query: \n\n" + query + "\n");

            if (isRoleMember(con, "sysadmin"))
                Console.WriteLine("[+] User is a member of sysadmin role");
            else
                Console.WriteLine("[-] User is NOT a member of sysadmin role");

            con.Close();
        }
    }
}
```


```
C:\Tools>MSSQL.exe DC_1.dom1.com master
[+] Auth success!
[+] Executed query:

SELECT SYSTEM_USER;

[+] Logged in as: dom1\offsec
[+] Executed query:

SELECT USER_NAME();

[+] Mapped to the user: guest
[+] Executed query:

SELECT IS_SRVROLEMEMBER('public');

[+] User is a member of public role
[+] Executed query:

SELECT IS_SRVROLEMEMBER('sysadmin');

[-] User is NOT a member of sysadmin role

```

```cs
        static void Main(string[] args)
        {
            if (args.Length != 2)
            {
                string codeBase = Assembly.GetExecutingAssembly().CodeBase;
                string progName = Path.GetFileName(codeBase);

                Console.WriteLine("[-] Please supply arguments, e.g.:");
                Console.WriteLine(String.Format("{0} {1} {2}", progName, "DC_1.dom1.com", "master"));
                return;
            }

            String sqlServer = args[0];
            String database = args[1];
            String conString = String.Format("Server = {0}; Database = {1}; Integrated Security = True;",
                sqlServer, database);

            SqlConnection con = new SqlConnection(conString);

            try
            {
                con.Open();
                Console.WriteLine("[+] Auth success!");
            }
            catch
            {
                Console.WriteLine("[-] Auth failed");
                Environment.Exit(0);
            }

            String query = "SELECT distinct b.name FROM sys.server_permissions a INNER JOIN ";
            query += "sys.server_principals b ON a.grantor_principal_id = b.principal_id ";
            query += "WHERE a.permission_name = 'IMPERSONATE'; ";

            Console.WriteLine("[+] Executed query: \n\n" + query + "\n");

            List<String> result = ExecuteQuery(con, query);

            Console.WriteLine("[*] Logins that can be impersonated: ");

            for (int i = 0; i < result.Count; i++)
                Console.WriteLine(result[i]);

            con.Close();
        }
```

```
C:\Tools>MSSQL.exe DC_1.dom1.com master
[+] Auth success!
[+] Executed query:

SELECT distinct b.name FROM sys.server_permissions a INNER JOIN sys.server_principals b ON a.grantor_principal_id = b.principal_id WHERE a.permission_name = 'IMPERSONATE';

[*] Logins that can be impoersonated:
sa

```


```cs
        static void Main(string[] args)
        {

            if (args.Length != 2)
            {
                string codeBase = Assembly.GetExecutingAssembly().CodeBase;
                string progName = Path.GetFileName(codeBase);

                Console.WriteLine("[-] Please supply arguments, e.g.:");
                Console.WriteLine(String.Format("{0} {1} {2}", progName, "DC_1.dom1.com", "master"));
                return;
            }

            String sqlServer = args[0];
            String database = args[1];
            String conString = String.Format("Server = {0}; Database = {1}; Integrated Security = True;",
                sqlServer, database);

            SqlConnection con = ConnectSQLServerIntegrated(conString);

            String execSP = "EXEC sp_linkedservers;";

            Console.WriteLine("[+] Executing query: \n\n" + execSP + "\n");

            List<String> resultList = ExecuteQuery(con, execSP);
            Console.WriteLine("[+] Current database: " + resultList[resultList.Count - 1] + "\n");

            if (resultList.Count > 1)
            {
                Console.WriteLine("[+] Linked databases: ");
                for (int i = 0; i < resultList.Count - 1; i++)
                    Console.WriteLine(resultList[i]);
            }
            else
                Console.WriteLine("[-] No linked databases!");

            con.Close();
        }
```

```
C:\Tools>MSSQL.exe DC_1.dom1.com master
[+] Auth success!
[+] Executing query:

EXEC sp_linkedservers;

[+] Current database: DC_1\SQLEXPRESS

[+] Linked databases:
app01

```
