const { exec } = require("child_process");
const express = require("express");

const app = express();
const PORT = 3000;

app.use(express.static("."));

app.get("/stats", (req, res) => {
  exec("./system-monitor.sh", (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing script: ${stderr}`);
      res.status(500).send({ error: "Script execution failed", details: stderr });
      return;
    }
    try {
      const json = JSON.parse(stdout);
      res.json(json);
    } catch (parseError) {
      console.error("Invalid JSON output:", stdout);
      res.status(500).send({ error: "Invalid JSON output", details: stdout });
    }
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
