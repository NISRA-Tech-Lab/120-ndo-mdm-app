<script>
  export let value;
  export let place;
  export let count;

  import { scaleColours } from '$lib/layout/ScaleColours.js';

  const markerWidth = 1.3229166;
  const boxHeight = 14;
  const boxY = -9.0;
  const gap = 6.4;
  const svgMinX = -1.3229166;
  const svgMaxX = 154.5487732;
  const scaleY = 7.0;

  $: x_position = value / count * -151.90294;
  $: markerCenter = -x_position - markerWidth / 2;
  $: placeName = place?.name?.replace(/_/g, ' ') || 'place';
  $: arrowFromLeft = value > count / 2;
  $: boxLabel = `rank: ${value}`;

  $: longestLine = Math.max(placeName.length, boxLabel.length);
  $: boxWidth = Math.max(28, longestLine * 2.8 + 5);

  $: boxX = arrowFromLeft
    ? Math.max(svgMinX, markerCenter - gap - boxWidth)
    : Math.min(svgMaxX - boxWidth, markerCenter + gap);

  $: boxMidY = boxY + boxHeight / 2;
</script>

<svg
  viewBox="-1.3229166 -10 154.5487732 40"
  xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker
      id="arrowHead"
      viewBox="0 0 8 6"
      refX="8"
      refY="3"
      markerWidth="8"
      markerHeight="6"
      orient="auto"
      markerUnits="strokeWidth">
      <path d="M0,0 L8,3 L0,6 L2,3 Z" fill="#042433" />
    </marker>
  </defs>

  <rect
    x={boxX}
    y={boxY}
    width={boxWidth}
    height={boxHeight}
    rx="0.3"
    fill="#ffffff"
    stroke="#042433"
    stroke-width="0.2" />

  <text
    x={boxX + 0.8}
    y={boxY + 1.5}
    fill="var(--nisra_blue)"
    font-size="5"
    font-family="sans-serif"
    dominant-baseline="hanging">
    <tspan x={boxX + 0.8} dy="0">{placeName}</tspan>
    <tspan x={boxX + 0.8} dy="6">{boxLabel}</tspan>
  </text>

  <line
    x1={arrowFromLeft ? boxX + boxWidth : boxX}
    y1={boxMidY}
    x2={markerCenter}
    y2={boxMidY}
    stroke="#042433"
    stroke-width="0.35" />

  <line
    x1={markerCenter}
    y1={boxMidY}
    x2={markerCenter}
    y2={scaleY}
    stroke="#042433"
    stroke-width="0.35"
    marker-end="url(#arrowHead)" />

  <g
    id="g10"
    transform="translate(-33.784712,-88.201939)">
    {#each scaleColours as color, i}
      <rect
        style="fill:{color};fill-opacity:1;stroke:#ffffff;stroke-width:0.79375"
        id="rect{i + 1}"
        width="16.710997"
        height="6.5831203"
        x={34.181587 + i * 14.933132}
        y="95.202042" />
    {/each}
  </g>
</svg>

<style>
  svg {
    width: 100%;
    height: auto;
    max-width: 980px;
    display: block;
  }
</style>