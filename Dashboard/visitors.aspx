<%@ Page Language="C#" MasterPageFile="~/Dashboard/MasterPage.master" Title="Visitors" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script type="text/C#" runat="server">

    protected void Page_Load()
    {
        Session["Section"] = "Visitors";

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = (OleDbConnection)Application["Con"];

        Com.CommandText = "select * from visitors where visits>2  and (DateDiff('d',[lastvisit],Now())) <90 order by lastvisit desc";

        OleDbDataReader R = Com.ExecuteReader();

        string result = "";

        while (R.Read())
        {
            DateTime d1 = DateTime.Now;

            if ((bool)(Application["IsRemote"]) == true) d1 = d1.AddHours(Convert.ToDouble(Application["Setting19"]));

            DateTime d2 = (DateTime)R["LastVisit"];

            TimeSpan dif = d1 - d2;

            string d = "";

            if (dif.Days > 0)
            {
                d = dif.Days.ToString() + " day" + ((dif.Days > 1) ? "s" : "");
            }
            else
            {
                if (dif.Hours > 0)
                {
                    d = dif.Hours.ToString() + " hour" + ((dif.Hours > 1) ? "s" : "");
                }
                else
                {
                    if (dif.Minutes > 0)
                    {
                        d = dif.Minutes.ToString() + " minute" + ((dif.Minutes > 1) ? "s" : "");
                    }
                    else
                    {
                        d = "1 minute ago";

                    }

                }
            }

            string cmt_name = R["CmtName"].ToString();

            string label = R["Label"].ToString();

            if (cmt_name != "") cmt_name = " (" + cmt_name + ")";

            if (label != "") cmt_name = " (" + label + ")";

            result += "<tr><td>"
            
                      + R["BrowserName"].ToString() + "</td><td>" + R["BrowserVersion"].ToString() + "</td><td>"

                      + R["Platform"].ToString() + "<td><b>" + R["Visits"].ToString() + "</b> visits</td><td>"

                      + d + " ago</td><td>" + R["IP"].ToString() + "</td><td>" + cmt_name + "</td></tr>"

            +"<tr><td colspan=7><hr/></td></tr>";


        }

        R.Close();

        Label2.Text = result;
    }

   
   
</script>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <table id="Dashboard" style="width: 900px;">
        <tr>
            <td id="Header">
                Visitors Log
            </td>
        </tr>
        <tr>
            <td id="Content">
            <table style="width :100%; font-family :Verdana ;font-size:11; margin :10px;">
            <tr>
            <td><b>Browser</b></td>
            <td><b>Version</b></td>
            <td><b>Operating System</b></td>
            <td><b>Visits</b></td>
            <td><b>Last Visit</b></td>
            <td><b>IP Address</b></td>
            <td><b>Label</b></td>
            
            
            </tr>
            
            
            
            <tr><td colspan =7><hr /></td></tr>
            <asp:Label ID="Label2" runat="server" />
         
            
            
            </table>
                
            </td>
        </tr>
    </table>
</asp:Content>
