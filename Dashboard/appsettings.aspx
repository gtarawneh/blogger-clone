<%@ Page Language="C#" MasterPageFile="~/Dashboard/MasterPage.master" Title="Application Settings" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script type="text/C#" runat="server">

    protected void Page_Load()
    {
        Session["Section"] = "Application Settings";

        ArrayList Blocked = (ArrayList)Application["Blocked"];

        for (int i = 0; i < Blocked.Count; i++) Label1.Text += Blocked[i].ToString() + "<br>";

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = (OleDbConnection)Application["Con"];

        Com.CommandText = "select * from visitors order by lastvisit desc";

        OleDbDataReader R = Com.ExecuteReader();

        string result = "";

        while (R.Read())
        {
            DateTime d1 = DateTime.Now;
            
            if ((bool)(Application["IsRemote"]) == true) d1 = d1.AddHours(Convert.ToDouble(Application["Setting19"]));

            DateTime d2 = (DateTime) R["LastVisit"];

            TimeSpan dif = d1 -d2;

            string d = "";

            if (dif.Days > 0)
            {
                d = dif.Days.ToString() + " day" + ((dif.Days >1) ? "s" : "");
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
                        d = "less than a minute";
                    }
                }
            }
            
            string cmt_name = R["CmtName"].ToString ();
            
            string label = R["Label"].ToString ();

            if (cmt_name != "") cmt_name = " (" + cmt_name + ")";

            if (label != "") cmt_name = " (<i><b>" + label + "</b></i>)";
            
            result += R["BrowserName"].ToString() + " " + R["BrowserVersion"].ToString() + " / "

                      + R["Platform"].ToString() + " , <b>" + R["Visits"].ToString() + "</b> visit(s) , last: <b>"

                      + d + " ago</b> (" + R["IP"].ToString ()+ ")" + cmt_name + "<br/>" ;
             
        }
        
        R.Close();
        
        Label2.Text = result;
    }

    protected void Button1_Click(object sender, EventArgs E)
    {
        if (FileUpload1.HasFile)
        {
            OleDbConnection Con = (OleDbConnection)Application["Con"];

            Con.Close();
            
            FileUpload1.SaveAs (MapPath ("~/Data/MyData.mdb"));
            
            Con.Open ();

            Application["DataReloaded"] = null;

            Session["MsgText"] = "The database has been replaced successfully!";

            Session["RedirectURL"] = "appsettings.aspx";

            Session["MsgButton"] = "Proceed";

            Response.Redirect("message.aspx");

        }
    }
   
</script>
<asp:Content ContentPlaceHolderID ="ContentPlaceHolder1" runat ="server" >
<table id="Dashboard" style="width: 900px;">
    <tr>
        <td id="Header">
            Application Settings
        </td>
    </tr>
    <tr>
        <td id="Content">
        
        <hr />
            Upload New Database: <asp:FileUpload ID ="FileUpload1" runat ="server" />
            
            <asp:Button ID="Button1" runat ="server" OnClick ="Button1_Click" Text ="Upload" />
            <hr />
            Blocked I.P Addresses:<br />
            <asp:Label ID="Label1" runat ="server" />
            <hr />
            
            <asp:Label ID="Label2" runat ="server" />

        </td>
    </tr>
</table>
</asp:Content> 