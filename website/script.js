document.addEventListener("DOMContentLoaded", function () {
    const featuresSection = document.querySelector(".features");
    const features = document.querySelectorAll(".feature");
  
    const observer = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            featuresSection.classList.add("show"); // Show the whole section
            features.forEach((feature, index) => {
              setTimeout(() => {
                feature.classList.add("show");
              }, index * 200); // Staggered effect for each feature
            });
            observer.unobserve(featuresSection); // Stop observing after it's visible
          }
        });
      },
      { threshold: 0.3 } // Trigger when 30% of the div is visible
    );
  
    observer.observe(featuresSection);
  });
  

  document.addEventListener("DOMContentLoaded", function() {
    const steps = document.querySelectorAll('.step');

    function checkSteps() {
        steps.forEach(step => {
            const rect = step.getBoundingClientRect();
            if (rect.top < window.innerHeight * 0.85) {
                step.classList.add('visible');
            }
        });
    }

    window.addEventListener('scroll', checkSteps);
    checkSteps();
  });