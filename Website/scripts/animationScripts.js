function playOnMouseover(id)
{
	element = document.getElementById(id); //get element
	style = getComputedStyle(element); //get style
	element.style = style; //make style editable
	/* ensures that while the animation can be played an infinite number of times, it doesn't loop independently */
	element.addEventListener('animationiteration', function(){element.style.animationPlayState = 'paused';});
	/* plays animation iteration on mouseover */
	element.addEventListener('mouseover', function(){element.style.animationPlayState = 'running';});
}