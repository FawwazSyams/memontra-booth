// src/sections/Gallery.jsx
import React, { useEffect } from 'react';
import AOS from 'aos';
import 'aos/dist/aos.css';

const Gallery = () => {
    useEffect(() => {
        AOS.init({ duration: 800, once: true });
    }, []);

    // Data dummy untuk galeri (Nanti ganti URL gambarnya dengan hasil foto/desain frame asli)
    const galleryItems = [
        { id: 1, title: "Wedding Frame Elegan", img: "https://placehold.co/600x800/1C7B7F/FFF?text=Wedding+1" },
        { id: 2, title: "Birthday Party Fun", img: "https://placehold.co/800x600/EFBF04/111?text=Birthday+1" },
        { id: 3, title: "Graduation Vibe", img: "https://placehold.co/600x800/111111/FFF?text=Graduation" },
        { id: 4, title: "Corporate Event", img: "https://placehold.co/800x600/1C7B7F/FFF?text=Corporate" },
        { id: 5, title: "Intimate Engagement", img: "https://placehold.co/600x800/EFBF04/111?text=Engagement" },
        { id: 6, title: "Kids Party Custom", img: "https://placehold.co/800x600/111111/FFF?text=Kids+Party" },
    ];

    return (
        <section id="galeri" className="py-24 bg-universal">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                {/* Header Galeri */}
                <div className="text-center max-w-3xl mx-auto mb-16" data-aos="fade-up">
                    <h2 className="text-secondary font-semibold tracking-wider uppercase text-sm mb-2">Galeri Momen</h2>
                    <h3 className="text-3xl md:text-4xl font-bold text-primary mb-4">
                        Intip Keseruan Bersama Kami
                    </h3>
                    <p className="text-dark/70 text-lg">
                        Beberapa contoh hasil cetak dan desain frame custom yang bisa disesuaikan dengan tema acaramu.
                    </p>
                </div>

                {/* Grid Galeri (Responsive: 1 kolom HP, 2 kolom Tablet, 3 kolom Desktop) */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                    {galleryItems.map((item, index) => (
                        <div
                            key={item.id}
                            data-aos="zoom-in"
                            data-aos-delay={index * 100}
                            className="group relative overflow-hidden rounded-2xl shadow-md cursor-pointer aspect-4/3"
                        >
                            {/* Gambar dengan efek zoom saat di-hover */}
                            <img
                                src={item.img}
                                alt={item.title}
                                className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                            />

                            {/* Overlay Gradient & Teks yang muncul saat di-hover */}
                            <div className="absolute inset-0 bg-linear-to-t from-dark/80 via-dark/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end">
                                <div className="p-6 w-full transform translate-y-4 group-hover:translate-y-0 transition-transform duration-300">
                                    <h4 className="text-universal font-bold text-lg">{item.title}</h4>
                                    <p className="text-secondary text-sm font-medium">Lihat Detail &rarr;</p>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Tombol Load More / IG */}
                <div className="mt-12 text-center" data-aos="fade-up">
                    <button className="border-2 border-primary text-primary hover:bg-primary hover:text-universal px-8 py-3 rounded-full font-semibold transition hover:scale-105">
                        Lihat Lebih Banyak di Instagram
                    </button>
                </div>

            </div>
        </section>
    );
};

export default Gallery;