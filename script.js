let cpuData = [];
let gpuData = [];
let memoryData = [];

const maxDataPoints = 10;

async function fetchSystemStats() {
  try {
    const response = await fetch("/stats");
    const text = await response.text();
    const stats = JSON.parse(text);

    const monitorDiv = document.getElementById("monitor");
    monitorDiv.innerHTML = `
      <div class="p-4 bg-gray-800 rounded shadow">
        <h2 class="text-xl font-semibold">CPU</h2>
        <canvas id="cpuChart" width="400" height="200"></canvas>
        <p>Usage: ${stats.cpu_usage}%</p>
        <p>Temperature: ${stats.cpu_temp}°C</p>
      </div>
      <div class="p-4 bg-gray-800 rounded shadow">
        <h2 class="text-xl font-semibold">GPU</h2>
        <canvas id="gpuChart" width="400" height="200"></canvas>
        <p>Utilization: ${stats.gpu_utilization || "N/A"}%</p>
        <p>Temperature: ${stats.gpu_temp || "N/A"}°C</p>
      </div>
      <div class="p-4 bg-gray-800 rounded shadow">
        <h2 class="text-xl font-semibold">Memory</h2>
        <canvas id="memoryChart" width="400" height="200"></canvas>
        <p>${stats.memory}%</p>
      </div>
      <div class="p-4 bg-gray-800 rounded shadow">
        <h2 class="text-xl font-semibold">Disk</h2>
        <div id="diskList"></div>
      </div>
      <div class="p-4 bg-gray-800 rounded shadow">
        <h2 class="text-xl font-semibold">System Load</h2>
        <p>${stats.load_avg}</p>
      </div>
      <div class="p-4 bg-gray-800 rounded shadow">
        <h2 class="text-xl font-semibold">Network</h2>
        <p>${stats.network_stats}</p>
      </div>
    `;

    // Render disk partitions dynamically
    const diskListDiv = document.getElementById("diskList");
    if (stats.disk_usage && stats.disk_usage.partitions) {
      const partitionList = stats.disk_usage.partitions
        .map((partition) => {
          return `
          <div class="p-2">
            <strong>Partition:</strong> ${partition.name} <br>
            <strong>Mountpoint:</strong> ${partition.mountpoint || "N/A"} <br>
            <strong>Usage:</strong> ${partition.usage || "N/A"} <br>
          </div>
        `;
        })
        .join("");
      diskListDiv.innerHTML = partitionList;
    } else {
      diskListDiv.innerHTML = "<p>No disk information available.</p>";
    }

    // Update chart data
    cpuData.push(stats.cpu_usage);
    gpuData.push(stats.gpu_utilization || 0);
    memoryData.push(stats.memory);

    if (cpuData.length > maxDataPoints) cpuData.shift();
    if (gpuData.length > maxDataPoints) gpuData.shift();
    if (memoryData.length > maxDataPoints) memoryData.shift();

    const cpuCtx = document.getElementById("cpuChart").getContext("2d");
    new Chart(cpuCtx, {
      type: "line",
      data: {
        labels: Array.from({ length: cpuData.length }, (_, i) => i),
        datasets: [
          {
            label: "CPU Usage (%)",
            data: cpuData,
            fill: false,
            borderColor: "rgb(75, 192, 192)",
            tension: 0.2,
          },
        ],
      },
      options: {
        animation: {
          duration: 0,
        },
      },
    });

    const gpuCtx = document.getElementById("gpuChart").getContext("2d");
    new Chart(gpuCtx, {
      type: "line",
      data: {
        labels: Array.from({ length: gpuData.length }, (_, i) => i),
        datasets: [
          {
            label: "GPU Utilization (%)",
            data: gpuData,
            fill: false,
            borderColor: "rgb(153, 102, 255)",
            tension: 0.2,
          },
        ],
      },
      options: {
        animation: {
          duration: 0,
        },
      },
    });

    const memoryCtx = document.getElementById("memoryChart").getContext("2d");
    new Chart(memoryCtx, {
      type: "line",
      data: {
        labels: Array.from({ length: memoryData.length }, (_, i) => i),
        datasets: [
          {
            label: "Memory Usage (%)",
            data: memoryData,
            fill: false,
            borderColor: "rgb(255, 159, 64)",
            tension: 0.2,
          },
        ],
      },
      options: {
        animation: {
          duration: 0,
        },
      },
    });
  } catch (error) {
    console.error("Error fetching system stats:", error);
  }
}

setInterval(fetchSystemStats, 1000);
