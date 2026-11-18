// src/sections/Contact.jsx
import React, { useEffect } from 'react';
import AOS from 'aos';
import 'aos/dist/aos.css';
import { FaEnvelope, FaWhatsapp, FaMapMarkerAlt } from 'react-icons/fa';

const Contact = () => {
    useEffect(() => {
        AOS.init({ duration: 800, once: true });
    }, []);

    const [formData, setFormData] = React.useState({
        name: '',
        contact: '',
        message: ''
    });

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.id]: e.target.value });
    };

    const [isSubmitting, setIsSubmitting] = React.useState(false);

    const handleSubmit = (e) => {
        e.preventDefault();
        setIsSubmitting(true);
        const { name, contact, message } = formData;

        // Nomor WA tujuan
        const waNumber = '6288218987242';

        // Format pesan otomatis
        const waText = `Halo Memontra Booth,%0A%0ANama: ${name}%0AKontak: ${contact}%0APesan: ${message}%0A%0AMohon infonya lebih lanjut, terima kasih.`;

        // Buka link WhatsApp di tab baru
        window.open(`https://wa.me/${waNumber}?text=${waText}`, '_blank');

        // Reset form
        setFormData({
            name: '',
            contact: '',
            message: ''
        });
        setIsSubmitting(false);
    };

    return (
        <section id="kontak" className="py-24 bg-primary/5">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                <div className="text-center max-w-3xl mx-auto mb-16" data-aos="fade-up">
                    <h2 className="text-secondary font-semibold tracking-wider uppercase text-sm mb-2">Hubungi Kami</h2>
                    <h3 className="text-3xl md:text-4xl font-bold text-primary mb-4">
                        Punya Pertanyaan?
                    </h3>
                    <p className="text-dark/70 text-lg">
                        Jangan ragu untuk menghubungi tim kami jika kamu butuh informasi lebih lanjut atau ingin custom paket.
                    </p>
                </div>

                <div className="flex flex-col lg:flex-row gap-12 bg-universal rounded-3xl overflow-hidden shadow-xl">

                    {/* Sisi Kiri: Informasi Kontak */}
                    <div className="lg:w-2/5 bg-primary text-universal p-10 md:p-12 flex flex-col justify-between" data-aos="fade-right">
                        <div>
                            <h4 className="text-2xl font-bold mb-6">Informasi Kontak</h4>
                            <p className="text-universal/80 mb-10 leading-relaxed">
                                Kirimkan pesanmu melalui form di samping, atau hubungi kami langsung lewat detail di bawah ini.
                            </p>

                            <div className="space-y-6">
                                <div className="flex items-start">
                                    <span className="text-secondary text-2xl shrink-0 mr-4"><FaMapMarkerAlt /></span>
                                    <div>
                                        <h5 className="font-semibold">Area Operasional</h5>
                                        <p className="text-universal/70 text-sm">Bandung, Cimahi, dan sekitarnya.</p>
                                    </div>
                                </div>
                                <div className="flex items-start">
                                    <span className="text-secondary text-2xl shrink-0 mr-4"><FaWhatsapp /></span>
                                    <div>
                                        <h5 className="font-semibold">WhatsApp</h5>
                                        <p className="text-universal/70 text-sm"><a href="https://wa.me/6288218987242?text=Halo%20Memontra%20Booth,%20saya%20tertarik%20dengan%20layanan%20photobooth-nya.%20Boleh%20minta%20info%20lebih%20lanjut?" target="_blank" rel="noopener noreferrer">+62 882-1898-7242</a></p>
                                    </div>
                                </div>
                                <div className="flex items-start">
                                    <span className="text-secondary text-2xl shrink-0 mr-4"><FaEnvelope /></span>
                                    <div>
                                        <h5 className="font-semibold">Email</h5>
                                        <p className="text-universal/70 text-sm"><a href="mailto:memontrabooth@gmail.com" target="_blank" rel="noopener noreferrer">memontrabooth@gmail.com</a></p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Sisi Kanan: Formulir Pesan Sederhana */}
                    <div className="lg:w-3/5 p-10 md:p-12" data-aos="fade-left">
                        <h4 className="text-2xl font-bold text-dark mb-6">Kirim Pesan</h4>
                        <form className="space-y-6" onSubmit={handleSubmit}>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label htmlFor="name" className="block text-sm font-medium text-dark/70 mb-2">Nama Lengkap</label>
                                    <input
                                        type="text"
                                        id="name"
                                        value={formData.name}
                                        onChange={handleChange}
                                        required
                                        className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                                        placeholder="Nama Anda"
                                    />
                                </div>
                                <div>
                                    <label htmlFor="contact" className="block text-sm font-medium text-dark/70 mb-2">Email / WhatsApp</label>
                                    <input
                                        type="text"
                                        id="contact"
                                        value={formData.contact}
                                        onChange={handleChange}
                                        required
                                        className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                                        placeholder="Email/WhatsApp yang bisa dihubungi"
                                    />
                                </div>
                            </div>

                            <div>
                                <label htmlFor="message" className="block text-sm font-medium text-dark/70 mb-2">Pesan</label>
                                <textarea
                                    id="message"
                                    rows="5"
                                    value={formData.message}
                                    onChange={handleChange}
                                    required
                                    className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none transition-all resize-none"
                                    placeholder="Tuliskan pertanyaanmu di sini..."
                                ></textarea>
                            </div>

                            <button
                                type="submit"
                                disabled={isSubmitting}
                                className="w-full bg-primary text-universal font-bold py-4 rounded-xl shadow-lg hover:bg-opacity-90 hover:-translate-y-1 transition-all duration-300"
                            >
                                {isSubmitting ? 'Mengirim...' : 'Kirim Pesan via WhatsApp'}
                            </button>

                        </form>
                    </div>
                </div>
            </div>
        </section>
    );
};

export default Contact;