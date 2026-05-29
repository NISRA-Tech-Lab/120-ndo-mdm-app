<script>

import { onMount } from 'svelte';
  import { afterNavigate } from '$app/navigation';
  import { base } from "$app/paths";
  import { tick } from 'svelte'; // Svelte's tick function ensures updates are applied before next DOM refresh.

  export let id;
  export let place;
  let card;
  let row;
  let i_button_info = {}; // Store the button info here
  let isExpanded = false; // Track the expanded state

function checkMeta (value) {

	let value_dotted = value.replaceAll("[", ".").replaceAll("]", "");
	let props = value_dotted.split(".");

	let rtn_value = place.meta_data;

	for (let i = 0; i < props.length; i ++) {

		if (rtn_value.hasOwnProperty(props[i])) {
			rtn_value = rtn_value[props[i]]
			if (props[i] == "last_updated") {
				let numbers = rtn_value.split("-");
				rtn_value =  numbers[2] + "/" + numbers[1] + "/" + numbers[0];
			}
		}

	}

	return rtn_value;

}

function cachangeAria () {
	card.ariaHidden = !row.ariaExpanded;
}

function get_i_button_info () {

	let info = {

		income_mdm : {
			info: "This measures the proportion of the population experiencing deprivation relating to low income."
		}


		}

	return info;

}

// Reactive statement that re-runs get_i_button_info when id or place changes
$: i_button_info = get_i_button_info();

// Ensure that get_i_button_info runs on component mount
onMount(() => {
  i_button_info = get_i_button_info();
});

// Ensure that get_i_button_info runs after every navigation
afterNavigate(() => {
  i_button_info = get_i_button_info();
});

// Function to reload HTML on click and expand/collapse the row
async function handleClick() {
  isExpanded = !isExpanded; // Toggle the expanded state
  i_button_info = get_i_button_info(); // Re-run the info update

  // Wait for Svelte to apply DOM updates
  await tick();
}

</script>

<div class="row"
	style="display: flex; cursor: pointer;"
	data-bs-toggle="collapse"
	data-bs-target="#{id}-info"
	aria-expanded="false"
	aria-controls="{id}-info"
	bind:this={row}
>
	<div class="blocktitle" on:click={changeAria}>
		 <img class = "i-button" src = "{base}\img\i-button.svg" alt = "Information button">
	</div>
</div>
<div class="collapse" id="{id}-info">
    <div class="card card-body" aria-hidden="true" bind:this={card}>
        {@html i_button_info[id].info} 
    </div>
</div>

<style>
	.card {
		--bs-card-spacer-y: 0.1rem;
		--bs-card-spacer-x: 0.5rem;
		--bs-card-title-spacer-y: 0.5rem;
		--bs-card-border-width: 1px;
		--bs-card-border-color: var(--bs-border-color-translucent);
		--bs-card-border-radius: 0.375rem;
		--bs-card-box-shadow: ;
		--bs-card-inner-border-radius: calc(0.375rem - 1px);
		--bs-card-cap-padding-y: 0.5rem;
		--bs-card-cap-padding-x: 1rem;
		--bs-card-cap-bg: rgba(0, 0, 0, 0.03);
		--bs-card-cap-color: ;
		--bs-card-height: ;
		--bs-card-color: ;
		--bs-card-bg: #fff;
		--bs-card-img-overlay-padding: 1rem;
		--bs-card-group-margin: 0.75rem;
		position: relative;
		display: flex;
		flex-direction: column;
		min-width: 0;
		height: var(--bs-card-height);
		word-wrap: break-word;
		background-color: var(--bs-card-bg);
		background-clip: border-box;
		border: var(--bs-card-border-width) solid var(--bs-card-border-color);
		border-radius: var(--bs-card-border-radius);
	}

	.card-body {
		flex: 1 1 auto;
		padding: var(--bs-card-spacer-y) var(--bs-card-spacer-x);
		color: var(--bs-card-color);
		font-size: 10pt;
		margin-bottom: 5px;
	}

	.collapse:not(.show) {
		display: none;
	}
	.collapsing {
		height: 0;
		overflow: hidden;
		transition: height 0.35s ease;
	}

	.show {
		display: block !important;
	}
</style>