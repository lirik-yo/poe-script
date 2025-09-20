document.addEventListener('DOMContentLoaded', () => {
    // Map navigation to content
    const tabMap = {
		'#tab-nav-items': '#tab-content-items',
		'#tab-nav-heroes': '#tab-content-heroes',
		'#tab-nav-neurons': '#tab-content-neurons'
    };

    // All navigation and content elements
    const navs = Object.keys(tabMap);
    const contents = Object.values(tabMap);

    //Tags that are clicked to input information
    const ignoreTagInput = ['input','select','textarea','button','option','select-one'];

    // Function to switch tabs
    function switchTab(event) {     
        if (ignoreTagInput.includes(event.target.type))
            return;//Drop event, if that not 
        
        // Remove active class from all navs and contents
        navs.forEach(navId => DomCache.Instance.get(navId).classList.remove('active'));
        contents.forEach(contentId => DomCache.Instance.get(contentId).classList.remove('active'));

        // Add active class to clicked nav and corresponding content    
        const nav = event.currentTarget;
        nav.classList.add('active');
        const content = DomCache.Instance.get(tabMap['#' + nav.id]);
        content.classList.add('active');
    }

    // Add click event listeners
    navs.forEach(navId => DomCache.Instance.get(navId).addEventListener('click', switchTab));

    // Initialize first tab as active
	Object.entries(tabMap)[0].forEach(id=>DomCache.Instance.get(id).classList.add('active'))
});