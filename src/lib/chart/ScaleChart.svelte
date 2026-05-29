<script>
  export let value;

 import { scaleColours } from '$lib/layout/ScaleColours.js';

  $: x_position = (value / 850 * -151.90294) - 1.3229166;
</script>


<svg
   viewBox="0 0 151.90294 10.583334"
   xmlns="http://www.w3.org/2000/svg">
   <g
     id="g10"
     transform="translate(-33.784712,-93.201939)">
      {#each scaleColours as color, i}
        <rect
          style="fill:{color};fill-opacity:1;stroke:#ffffff;stroke-width:0.79375"
          id="rect{i + 1}"
          width="16.710997"
          height="6.5831203"
          x="{34.181587 + (i * 14.933132)}"
          y="95.202042" />
      {/each}
    </g>
     <rect
      x="{x_position}"
      y="0.2645835"
      width="1.3229166"
      height="10.054167"
      stroke="#042433"
      stroke-width="0.529167"
      stroke-miterlimit="8"
      fill="#f8f8f8"
      transform="scale(-1,1)"
      id="marker"
      inkscape:label="marker" />
     </svg>


<style>
  svg {
    width: 100%;
    height: auto;
    max-width: 600px;
    display: block;
  }
</style>