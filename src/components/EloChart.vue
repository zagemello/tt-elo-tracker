<template>
  <div class="chart">
    <Line :data="chartData" :options="chartOptions" />
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'
import { formatDate } from '@/lib/format'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler)

const props = defineProps({
  history: { type: Array, default: () => [] },
  history2: { type: Array, default: () => [] },
  label1: { type: String, default: 'Player' },
  label2: { type: String, default: null },
})

// Chart.js draws to canvas, so it can't read CSS vars directly: resolve tokens once per render.
function token(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim()
}

function series(data, label, color, fill) {
  return {
    label,
    data: data.map((h) => h.new_elo),
    borderColor: color,
    backgroundColor: fill,
    tension: 0.3,
    fill: true,
    pointRadius: data.length > 30 ? 0 : 3,
    pointHoverRadius: 5,
    borderWidth: 2,
  }
}

const chartData = computed(() => {
  const accent = token('--color-accent')
  const datasets = [series(props.history, props.label1, accent, token('--color-accent-soft'))]

  if (props.history2.length) {
    datasets.push(series(props.history2, props.label2 ?? 'Player 2', token('--color-win'), token('--color-win-soft')))
  }

  const longest = props.history.length >= props.history2.length ? props.history : props.history2
  return { labels: longest.map((h) => formatDate(h.recorded_at, { year: false })), datasets }
})

const chartOptions = computed(() => {
  const muted = token('--color-text-muted')
  const grid = token('--color-line')
  return {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: { display: !!props.label2, labels: { color: muted, boxWidth: 12 } },
      tooltip: { mode: 'index', intersect: false },
    },
    scales: {
      x: { ticks: { color: muted, maxTicksLimit: 6, maxRotation: 0 }, grid: { display: false } },
      y: { ticks: { color: muted, maxTicksLimit: 5 }, grid: { color: grid } },
    },
  }
})
</script>

<style scoped>
.chart {
  position: relative;
  height: clamp(200px, 40vw, 320px);
}
</style>
