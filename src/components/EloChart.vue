<template>
  <Line :data="chartData" :options="chartOptions" />
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
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend, Filler)

const props = defineProps({
  history: { type: Array, default: () => [] },
  history2: { type: Array, default: () => [] },
  label1: { type: String, default: 'Player' },
  label2: { type: String, default: null },
})

function formatDate(iso) {
  return new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })
}

const chartData = computed(() => {
  const datasets = [
    {
      label: props.label1,
      data: props.history.map((h) => h.new_elo),
      borderColor: '#3b82f6',
      backgroundColor: 'rgba(59,130,246,0.08)',
      tension: 0.3,
      fill: true,
      pointRadius: 4,
    },
  ]

  if (props.history2.length) {
    datasets.push({
      label: props.label2 ?? 'Player 2',
      data: props.history2.map((h) => h.new_elo),
      borderColor: '#f97316',
      backgroundColor: 'rgba(249,115,22,0.08)',
      tension: 0.3,
      fill: true,
      pointRadius: 4,
    })
  }

  const labels =
    props.history.length >= (props.history2?.length ?? 0)
      ? props.history.map((h) => formatDate(h.recorded_at))
      : props.history2.map((h) => formatDate(h.recorded_at))

  return { labels, datasets }
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: { display: !!props.label2 },
    tooltip: { mode: 'index', intersect: false },
  },
  scales: {
    y: { ticks: { stepSize: 50 } },
  },
}
</script>
