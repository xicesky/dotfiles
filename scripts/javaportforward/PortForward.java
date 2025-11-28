import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;

/* Usage e.g.:
    kmipjavaexec PortForward.java 10080 google.com 80 &; kube port-forward "$(_kmip_pod_name "$pod")" 10080:10080 &;
    kmipjavaexec PortForward.java 5432 "$PGHOST" "$PGPORT" &; kube port-forward "$(_kmip_pod_name "$pod")" 5432:5432 &;
*/

public class PortForward {
    final int listeningTcpPort;
    final String remoteAddress;
    final int remoteTcpPort;

    public PortForward(int listeningTcpPort, String remoteAddress, int remoteTcpPort) {
        this.listeningTcpPort = listeningTcpPort;
        this.remoteAddress = remoteAddress;
        this.remoteTcpPort = remoteTcpPort;
    }

    public void run() throws IOException {
        System.out.printf("Server running to forward connections on port %d to %s:%d\n", listeningTcpPort, remoteAddress, remoteTcpPort);
        try (var serverSocket = new ServerSocket(listeningTcpPort)) {
            while (true) {
                try {
                    Socket clientSocket = serverSocket.accept();
                    var forwardThread = new ForwardServerClientThread(this, clientSocket);
                    forwardThread.start();
                } catch (Exception e) {
                    throw new Exception("Unexpected error.\n" + e.toString(), e);
                }
            }
        } catch (Exception ioe) {
            throw new IOException("Unable to bind to port " + listeningTcpPort);
        }
//        System.out.print("Server terminated\n");
    }

    public static void main(String[] args) {
        var listeningTcpPort = Integer.parseInt(args[0]);
        var remoteAddress = args[1];
        var remoteTcpPort = Integer.parseInt(args[2]);
        try {
            new PortForward(listeningTcpPort, remoteAddress, remoteTcpPort).run();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

class ForwardServerClientThread extends Thread {
    final PortForward parent;
    final Socket clientSocket;
    Socket serverSocket;

    public ForwardServerClientThread(PortForward parent, Socket clientSocket) {
        this.parent = parent;
        this.clientSocket = clientSocket;
    }

    public void run() {
        try {
            System.out.printf("Client connected from %s:%d\n", clientSocket.getInetAddress().getHostAddress(), clientSocket.getPort());
            serverSocket = new Socket(parent.remoteAddress, parent.remoteTcpPort);

            // Obtain input and output streams of server and client
            InputStream clientIn = clientSocket.getInputStream();
            OutputStream clientOut = clientSocket.getOutputStream();
            InputStream serverIn = serverSocket.getInputStream();
            OutputStream serverOut = serverSocket.getOutputStream();

            System.out.printf("    forwarding %s:%d <-> %s:%d\n",
                    clientSocket.getInetAddress().getHostAddress(), clientSocket.getPort(),
                    serverSocket.getInetAddress().getHostAddress(), serverSocket.getPort()
            );

            // Start forwarding of socket data between server and client
            ForwardThread clientForward = new ForwardThread(this, clientIn, serverOut);
            ForwardThread serverForward = new ForwardThread(this, serverIn, clientOut);
            clientForward.start();
            serverForward.start();

        } catch (IOException ioe) {
            ioe.printStackTrace();
        }
    }

    public void stopServer() {
        try { clientSocket.close(); } catch (IOException ignored) {}
        try { serverSocket.close(); } catch (IOException ignored) {}
    }
}

class ForwardThread extends Thread {
    private static final int BUFFER_SIZE = 8192;

    final ForwardServerClientThread parent;
    final InputStream inputStream;
    final OutputStream outputStream;

    public ForwardThread(ForwardServerClientThread parent, InputStream inputStream, OutputStream outputStream) {
        this.parent = parent;
        this.inputStream = inputStream;
        this.outputStream = outputStream;
    }

    public void run() {
        byte[] buffer = new byte[BUFFER_SIZE];
        try {
            while (true) {
                int bytesRead = inputStream.read(buffer);
                if (bytesRead == -1)
                    break; // End of stream is reached --> exit
                outputStream.write(buffer, 0, bytesRead);
                outputStream.flush();
            }
        } catch (IOException e) {
            // Read/write failed --> connection is broken
        }
        parent.stopServer();
    }
}
