(function () {
    const sidebar = document.getElementById('sidebar');
    const toggle = document.getElementById('sidebarToggle');
    const mobileBtn = document.getElementById('mobileMenuBtn');
    const backdrop = document.getElementById('sidebarBackdrop');

    if (!sidebar) return;

    const isDesktop = () => window.matchMedia('(min-width: 901px)').matches;

    if (localStorage.getItem('hrmsSidebarCollapsed') === 'true' && isDesktop()) {
        sidebar.classList.add('collapsed');
    }

    toggle?.addEventListener('click', function () {
        if (!isDesktop()) {
            sidebar.classList.toggle('open');
            backdrop?.classList.toggle('open', sidebar.classList.contains('open'));
            return;
        }
        sidebar.classList.toggle('collapsed');
        localStorage.setItem('hrmsSidebarCollapsed', sidebar.classList.contains('collapsed'));
    });

    mobileBtn?.addEventListener('click', function () {
        sidebar.classList.add('open');
        backdrop?.classList.add('open');
    });

    backdrop?.addEventListener('click', function () {
        sidebar.classList.remove('open');
        backdrop.classList.remove('open');
    });

    window.addEventListener('resize', function () {
        if (isDesktop()) {
            sidebar.classList.remove('open');
            backdrop?.classList.remove('open');
        }
    });
})();
