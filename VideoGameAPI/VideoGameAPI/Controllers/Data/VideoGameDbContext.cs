using Microsoft.EntityFrameworkCore;
using VideoGameAPI.Models;

namespace VideoGameAPI.Controllers.Data
{
    public class VideoGameDbContext(DbContextOptions<VideoGameDbContext> options): DbContext(options)
    {
        public DbSet<MultiNumbers> MultipleNumbers => Set<MultiNumbers>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<MultiNumbers>().HasData(
                new MultiNumbers
                {
                    Id = 1,
                    numberOne = 10,
                    numberTwo = 10
                },
                new MultiNumbers
                {
                    Id = 2,
                    numberOne = 20,
                    numberTwo = 10
                }
                );
        }
    }


    
}
